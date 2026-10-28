-- microsecond precision and plain index instead of unique key
alter table stock_movements
    modify created_at DATETIME(6) not null default CURRENT_TIMESTAMP(6);

-- index on inventory_records_id for the FK
alter table stock_movements
    add index stock_movements_inventory_records_id_created_at_idx (inventory_records_id, created_at);

alter table stock_movements
    drop index stock_movements_inventory_records_id_created_at_uk;

-- detach from the source address when it is deleted
alter table address_snapshots
    drop foreign key address_snapshots_source_id_fk;

alter table address_snapshots
    modify source_id BIGINT null;

alter table address_snapshots
    add constraint address_snapshots_source_id_fk
        foreign key (source_id) references addresses (id)
            on delete set null;

-- soft delete for entities referenced by history
alter table products   add column deleted_at DATETIME null;
alter table warehouses add column deleted_at DATETIME null;
alter table users      add column deleted_at DATETIME null;