use anyhow::{anyhow, Context, Error};

use substreams_database_change::pb::database::DatabaseChanges;
use substreams_database_change::tables::{Row, Tables};
use substreams_solana::pb::sf::solana::r#type::v1::{Block, ConfirmedTransaction};

use substreams_solana_utils::spl_token::constants::TOKEN_PROGRAM_ID;
use substreams_solana_utils::system_program::constants::SYSTEM_PROGRAM_ID;
use substreams_solana_utils::transaction::{
    get_context, get_signature, get_signers, TransactionContext,
};

use frens_substream;
use frens_substream::frens::FRENS_PROGRAM_ID;
use frens_substream::pb::substreams::v1::program::frens_event;

use system_program_substream;
use system_program_substream::pb::system_program::system_program_event;

mod instruction;
use instruction::{get_indexed_instructions, IndexedInstruction, IndexedInstructions};

#[substreams::handlers::map]
fn block_database_changes(block: Block) -> Result<DatabaseChanges, Error> {
    let mut tables = Tables::new();
    for (index, transaction) in block.transactions.iter().enumerate() {
        match parse_transaction(
            transaction,
            index as u32,
            block.slot,
            &block.blockhash,
            &mut tables,
        )? {
            true => {
                let signers = get_signers(transaction);
                let row = tables
                    .create_row(
                        "transactions",
                        [
                            ("slot", block.slot.to_string()),
                            ("transaction_index", index.to_string()),
                        ],
                    )
                    .set("signature", get_signature(transaction))
                    .set("number_of_signers", signers.len().to_string());
                for i in 0..8 {
                    row.set(&format!("signer{i}"), signers.get(i).unwrap_or(&"".into()));
                }
            }
            false => (),
        }
    }
    tables
        .create_row("blocks", block.slot.to_string())
        .set("parent_slot", block.parent_slot)
        .set(
            "block_height",
            block.block_height.as_ref().unwrap().block_height,
        )
        .set("blockhash", block.blockhash)
        .set("previous_blockhash", block.previous_blockhash)
        .set("block_time", block.block_time.as_ref().unwrap().timestamp);
    Ok(tables.to_database_changes())
}

fn parse_transaction<'a>(
    transaction: &ConfirmedTransaction,
    transaction_index: u32,
    slot: u64,
    blockhash: &String,
    tables: &mut Tables,
) -> Result<bool, Error> {
    if let Some(_) = transaction.meta.as_ref().unwrap().err {
        return Ok(false);
    }

    let instructions = get_indexed_instructions(transaction)?;
    let mut context = get_context(transaction)?;

    let mut tables_changed = false;
    for instruction in instructions.flattened().iter() {
        context.update_balance(&instruction.instruction.instruction);
        match parse_instruction(
            transaction,
            instruction,
            &context,
            tables,
            slot,
            transaction_index,
        )
        .with_context(|| format!("Transaction {}", context.signature))?
        {
            Some(row) => {
                row.set("partial_signature", &context.signature[0..4])
                    .set("partial_blockhash", &blockhash[0..4]);
                tables_changed = true;
            }
            None => (),
        }
    }

    Ok(tables_changed)
}

fn parse_instruction<'a>(
    transaction: &ConfirmedTransaction,
    instruction: &IndexedInstruction,
    context: &TransactionContext,
    tables: &'a mut Tables,
    slot: u64,
    transaction_index: u32,
) -> Result<Option<&'a mut Row>, Error> {
    let program_id = instruction.program_id();
    let row = if program_id == FRENS_PROGRAM_ID {
        parse_frens_instruction(
            transaction,
            instruction,
            context,
            tables,
            slot,
            transaction_index,
        )
    } else {
        return Ok(None);
    }?;

    if let Some(row) = row {
        if let Some(parent_instruction) = instruction.parent_instruction() {
            let top_instruction = instruction.top_instruction().unwrap();
            row.set(
                "parent_instruction_program_id",
                parent_instruction.program_id().to_string(),
            )
            .set("parent_instruction_index", parent_instruction.index)
            .set(
                "top_instruction_program_id",
                top_instruction.program_id().to_string(),
            )
            .set("top_instruction_index", top_instruction.index);
        } else {
            row.set("parent_instruction_program_id", "")
                .set("parent_instruction_index", -1)
                .set("top_instruction_program_id", "")
                .set("top_instruction_index", -1);
        }
        Ok(Some(row))
    } else {
        Ok(None)
    }
}

fn parse_frens_instruction<'a>(
    transaction: &ConfirmedTransaction,
    instruction: &IndexedInstruction,
    context: &TransactionContext,
    tables: &'a mut Tables,
    slot: u64,
    transaction_index: u32,
) -> Result<Option<&'a mut Row>, Error> {
    let row = match frens_substream::parse_instruction(
        &transaction,
        &instruction.instruction,
        context,
    )? {
        Some(frens_event::Event::PoolCreateEvent(create)) => {
            let mint_param = create.base_mint_param.unwrap();
            let vesting = create.vesting_param.unwrap();

            tables
                .create_row(
                    "frens_pool_create_events",
                    [
                        ("slot", slot.to_string()),
                        ("transaction_index", transaction_index.to_string()),
                        ("instruction_index", instruction.index.to_string()),
                    ],
                )
                .set("trx_hash", create.trx_hash)
                .set("platform_id", create.platform_id)
                .set("pool_state", create.pool_state)
                .set("creator", create.creator)
                .set("config", create.config)
                .set("curve_name", mint_param.name)
                .set("symbol", mint_param.symbol)
                .set("uri", mint_param.uri)
                .set("decimals", mint_param.decimals)
                .set("curve_param", create.curve_param)
                .set("total_locked_amount", vesting.total_locked_amount)
                .set("cliff_period", vesting.cliff_period)
                .set("unlock_period", vesting.unlock_period)
        }

        Some(frens_event::Event::TradeEvent(trade)) => tables
            .create_row(
                "frens_trade_events",
                [
                    ("slot", slot.to_string()),
                    ("transaction_index", transaction_index.to_string()),
                    ("instruction_index", instruction.index.to_string()),
                ],
            )
            .set("trx_hash", trade.trx_hash)
            .set("platform_id", trade.platform_id)
            .set("total_base_sell", trade.total_base_sell)
            .set("virtual_base", trade.virtual_base)
            .set("virtual_quote", trade.virtual_quote)
            .set("real_base_before", trade.real_base_before)
            .set("real_quote_before", trade.real_quote_before)
            .set("real_base_after", trade.real_base_after)
            .set("real_quote_after", trade.real_quote_after)
            .set("amount_in", trade.amount_in)
            .set("amount_out", trade.amount_out)
            .set("protocol_fee", trade.protocol_fee)
            .set("platform_fee", trade.platform_fee)
            .set("share_fee", trade.share_fee)
            .set("trade_direction", trade.trade_direction)
            .set("pool_status", trade.pool_status),

        Some(frens_event::Event::CreateVestingEvent(create)) => tables
            .create_row(
                "frens_create_vesting_events",
                [
                    ("slot", slot.to_string()),
                    ("transaction_index", transaction_index.to_string()),
                    ("instruction_index", instruction.index.to_string()),
                ],
            )
            .set("trx_hash", create.trx_hash)
            .set("pool_state", create.pool_state)
            .set("beneficiary", create.beneficiary)
            .set("share_amount", create.share_amount),

        Some(frens_event::Event::ClaimVested(vested)) => tables
            .create_row(
                "frens_claim_vested_events",
                [
                    ("slot", slot.to_string()),
                    ("transaction_index", transaction_index.to_string()),
                    ("instruction_index", instruction.index.to_string()),
                ],
            )
            .set("trx_hash", vested.trx_hash)
            .set("pool_state", vested.pool_state)
            .set("beneficiary", vested.beneficiary)
            .set("claim_amount", vested.claim_amount),
        None => return Ok(None),
    };
    Ok(Some(row))
}
