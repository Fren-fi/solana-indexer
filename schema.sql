-- BLOCKS

CREATE TABLE blocks (
    slot BIGINT NOT NULL,
    parent_slot BIGINT NOT NULL,
    block_height BIGINT NOT NULL,
    blockhash VARCHAR NOT NULL,
    previous_blockhash VARCHAR NOT NULL,
    block_time TIMESTAMP NOT NULL,
    insertion_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (slot)
);

-- TRANSACTIONS

CREATE TABLE transactions (
    slot BIGINT NOT NULL,
    transaction_index BIGINT NOT NULL,
    signature VARCHAR NOT NULL,
    number_of_signers SMALLINT NOT NULL,
    signer0 VARCHAR NOT NULL,
    signer1 VARCHAR DEFAULT '',
    signer2 VARCHAR DEFAULT '',
    signer3 VARCHAR DEFAULT '',
    signer4 VARCHAR DEFAULT '',
    signer5 VARCHAR DEFAULT '',
    signer6 VARCHAR DEFAULT '',
    signer7 VARCHAR DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (slot, transaction_index)
);

CREATE INDEX idx_transactions_signature ON transactions (signature);

-- FRENS EVENTS

CREATE TABLE frens_pool_create_events (
    slot BIGINT NOT NULL,
    transaction_index BIGINT NOT NULL,
    instruction_index BIGINT NOT NULL,
    partial_signature VARCHAR NOT NULL,
    partial_blockhash VARCHAR NOT NULL,
    trx_hash VARCHAR NOT NULL,
    platform_id VARCHAR NOT NULL,
    pool_state VARCHAR NOT NULL,
    creator VARCHAR NOT NULL,
    config VARCHAR NOT NULL,
    curve_name VARCHAR NOT NULL,
    symbol VARCHAR NOT NULL,
    uri VARCHAR NOT NULL,
    decimals SMALLINT NOT NULL,
    curve_param VARCHAR NOT NULL,
    total_locked_amount BIGINT DEFAULT 0,
    cliff_period BIGINT DEFAULT 0,
    unlock_period BIGINT DEFAULT 0,
    parent_instruction_index BIGINT DEFAULT -1,
    top_instruction_index BIGINT DEFAULT -1,
    parent_instruction_program_id VARCHAR DEFAULT '',
    top_instruction_program_id VARCHAR DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (slot, transaction_index, instruction_index)
);

CREATE TABLE frens_trade_events (
    slot BIGINT NOT NULL,
    transaction_index BIGINT NOT NULL,
    instruction_index BIGINT NOT NULL,
    partial_signature VARCHAR NOT NULL,
    partial_blockhash VARCHAR NOT NULL,
    trx_hash VARCHAR NOT NULL,
    platform_id VARCHAR NOT NULL,
    total_base_sell BIGINT DEFAULT 0,
    virtual_base BIGINT DEFAULT 0,
    virtual_quote BIGINT DEFAULT 0,
    real_base_before BIGINT DEFAULT 0,
    real_quote_before BIGINT DEFAULT 0,
    real_base_after BIGINT DEFAULT 0,
    real_quote_after BIGINT DEFAULT 0,
    amount_in BIGINT DEFAULT 0,
    amount_out BIGINT DEFAULT 0,
    protocol_fee BIGINT DEFAULT 0,
    platform_fee BIGINT DEFAULT 0,
    share_fee BIGINT DEFAULT 0,
    trade_direction VARCHAR NOT NULL,
    pool_status VARCHAR NOT NULL,
    parent_instruction_index BIGINT DEFAULT -1,
    top_instruction_index BIGINT DEFAULT -1,
    parent_instruction_program_id VARCHAR DEFAULT '',
    top_instruction_program_id VARCHAR DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (slot, transaction_index, instruction_index)
);

CREATE TABLE frens_create_vesting_events (
    slot BIGINT NOT NULL,
    transaction_index BIGINT NOT NULL,
    instruction_index BIGINT NOT NULL,
    partial_signature VARCHAR NOT NULL,
    partial_blockhash VARCHAR NOT NULL,
    trx_hash VARCHAR NOT NULL,
    pool_state VARCHAR NOT NULL,
    beneficiary VARCHAR NOT NULL,
    share_amount BIGINT DEFAULT 0,
    parent_instruction_index BIGINT DEFAULT -1,
    top_instruction_index BIGINT DEFAULT -1,
    parent_instruction_program_id VARCHAR DEFAULT '',
    top_instruction_program_id VARCHAR DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (slot, transaction_index, instruction_index)
);

CREATE TABLE frens_claim_vested_events (
    slot BIGINT NOT NULL,
    transaction_index BIGINT NOT NULL,
    instruction_index BIGINT NOT NULL,
    partial_signature VARCHAR NOT NULL,
    partial_blockhash VARCHAR NOT NULL,
    trx_hash VARCHAR NOT NULL,
    pool_state VARCHAR NOT NULL,
    beneficiary VARCHAR NOT NULL,
    claim_amount BIGINT DEFAULT 0,
    parent_instruction_index BIGINT DEFAULT -1,
    top_instruction_index BIGINT DEFAULT -1,
    parent_instruction_program_id VARCHAR DEFAULT '',
    top_instruction_program_id VARCHAR DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (slot, transaction_index, instruction_index)
);