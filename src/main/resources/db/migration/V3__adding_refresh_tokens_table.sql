create table refresh_tokens
(
    id          BIGINT auto_increment              not null
        primary key,
    user_id     BINARY(16)                         not null,
    token_hash  CHAR(64)                           not null,
    family_id   BINARY(16)                         not null,
    expires_at  DATETIME                           not null,
    revoked_at  DATETIME                           null,
    created_at  DATETIME default CURRENT_TIMESTAMP not null,
    constraint refresh_tokens_token_hash_uk
        unique (token_hash),
    constraint refresh_tokens_user_id_fk
        foreign key (user_id) references users (id)
            on delete cascade
);

create index refresh_tokens_family_id_idx on refresh_tokens (family_id);