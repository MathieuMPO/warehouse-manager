-- orders needed UUID for consistency/security reasons
alter table order_items
    drop constraint order_items_order_id_fk;

alter table orders
    modify column id BINARY(16) default (uuid_to_bin(uuid())) not null;

alter table order_items
    modify column order_id BINARY(16) not null,
    add constraint order_items_order_id_fk
        foreign key (order_id) references orders (id);