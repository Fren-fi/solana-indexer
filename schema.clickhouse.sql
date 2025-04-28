-- FUNCTIONS

-- BLOCKS

CREATE TABLE blocks
(
    slot UInt64,
    parent_slot UInt64,
    block_height UInt64,
    blockhash String,
    previous_blockhash String,
    block_time DateTime,
    insertion_time DateTime MATERIALIZED now(),
)
ENGINE = MergeTree
PRIMARY KEY slot
ORDER BY slot;

-- TRANSACTIONS

CREATE TABLE transactions
(
    slot UInt64,
    transaction_index UInt64,
    signature String,
    number_of_signers UInt8,
    signer0 String,
    signer1 String DEFAULT '',
    signer2 String DEFAULT '',
    signer3 String DEFAULT '',
    signer4 String DEFAULT '',
    signer5 String DEFAULT '',
    signer6 String DEFAULT '',
    signer7 String DEFAULT '',
    -- signers Array(String),
    PROJECTION projection_signature (SELECT * ORDER BY signature) -- RECOMMENDED
)
ENGINE = MergeTree
PARTITION BY toInt64(slot / 1e6)
PRIMARY KEY (slot, transaction_index)
ORDER BY (slot, transaction_index);

-- FRENS EVENTS

CREATE TABLE frens_pool_create_events
(
    slot UInt64,
    transaction_index UInt64,
    instruction_index UInt64,
    partial_signature String,
    partial_blockhash String,
    trx_hash String,
    platform_id String,
    mint String,
    pool_state String,
    creator String,   
    config String,
    curve_name String,
    symbol String,
    uri String,
    decimals UInt8,         
    curve_param String,
    total_locked_amount UInt64 DEFAULT 0,
    cliff_period UInt64 DEFAULT 0,
    unlock_period UInt64 DEFAULT 0,
    parent_instruction_index Int64 DEFAULT -1,
    top_instruction_index Int64 DEFAULT -1,
    parent_instruction_program_id LowCardinality(String) DEFAULT '' CODEC(LZ4),
    top_instruction_program_id LowCardinality(String) DEFAULT '' CODEC(LZ4),
)
ENGINE = MergeTree
PRIMARY KEY (slot, transaction_index, instruction_index)
ORDER BY (slot, transaction_index, instruction_index);

CREATE TABLE frens_trade_events
(
    slot UInt64,
    transaction_index UInt64,
    instruction_index UInt64,
    partial_signature String,
    partial_blockhash String,
    trx_hash String,
    platform_id String,
    mint String,
    total_base_sell UInt64 DEFAULT 0,
    virtual_base UInt64 DEFAULT 0,
    virtual_quote UInt64 DEFAULT 0,
    real_base_before UInt64 DEFAULT 0,
    real_quote_before UInt64 DEFAULT 0,
    real_base_after UInt64 DEFAULT 0,
    real_quote_after UInt64 DEFAULT 0,
    amount_in UInt64 DEFAULT 0,
    amount_out UInt64 DEFAULT 0,
    protocol_fee UInt64 DEFAULT 0,
    platform_fee UInt64 DEFAULT 0,
    share_fee UInt64 DEFAULT 0,
    trade_direction String,
    pool_status String,
    parent_instruction_index Int64 DEFAULT -1,
    top_instruction_index Int64 DEFAULT -1,
    parent_instruction_program_id LowCardinality(String) DEFAULT '' CODEC(LZ4),
    top_instruction_program_id LowCardinality(String) DEFAULT '' CODEC(LZ4),
)
ENGINE = MergeTree
PRIMARY KEY (slot, transaction_index, instruction_index)
ORDER BY (slot, transaction_index, instruction_index);

CREATE TABLE frens_create_vesting_events
(
    slot UInt64,
    transaction_index UInt64,
    instruction_index UInt64,
    partial_signature String,
    partial_blockhash String,
    trx_hash String,
    pool_state String,
    beneficiary String,
    share_amount UInt64 DEFAULT 0,
    parent_instruction_index Int64 DEFAULT -1,
    top_instruction_index Int64 DEFAULT -1,
    parent_instruction_program_id LowCardinality(String) DEFAULT '' CODEC(LZ4),
    top_instruction_program_id LowCardinality(String) DEFAULT '' CODEC(LZ4),
)
ENGINE = MergeTree
PRIMARY KEY (slot, transaction_index, instruction_index)
ORDER BY (slot, transaction_index, instruction_index);

CREATE TABLE frens_claim_vested_events
(
    slot UInt64,
    transaction_index UInt64,
    instruction_index UInt64,
    partial_signature String,
    partial_blockhash String,
    trx_hash String,
    pool_state String,
    beneficiary String,
    claim_amount UInt64 DEFAULT 0,
    parent_instruction_index Int64 DEFAULT -1,
    top_instruction_index Int64 DEFAULT -1,
    parent_instruction_program_id LowCardinality(String) DEFAULT '' CODEC(LZ4),
    top_instruction_program_id LowCardinality(String) DEFAULT '' CODEC(LZ4),
)
ENGINE = MergeTree
PRIMARY KEY (slot, transaction_index, instruction_index)
ORDER BY (slot, transaction_index, instruction_index);