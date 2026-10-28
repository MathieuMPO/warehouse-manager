-- User related --
create table users
(
    id            BINARY(16) default (uuid_to_bin(uuid()))   not null
        primary key,
    name          VARCHAR(100) not null,
    email         VARCHAR(254) not null,
    password_hash VARCHAR(255) not null,
    phone_number  VARCHAR(15)  not null,
    created_at    DATETIME default CURRENT_TIMESTAMP         not null,
    role          VARCHAR(20)  not null,
    constraint users_email_uk
        unique (email),
    constraint users_phone_number_uk
        unique (phone_number)
);

create table addresses
(
    id            BIGINT auto_increment              not null
        primary key,
    street        VARCHAR(255) not null,
    city          VARCHAR(100) not null,
    zip           VARCHAR(20)  not null,
    country       VARCHAR(2)   not null,
    created_at    DATETIME default CURRENT_TIMESTAMP not null,
    type          VARCHAR(20)  not null
);

create table address_snapshots
(
    id            BIGINT auto_increment              not null
        primary key,
    source_id     BIGINT       not null,
    street        VARCHAR(255) not null,
    city          VARCHAR(100) not null,
    zip           VARCHAR(20)  not null,
    country       VARCHAR(2)   not null,
    snapped_at    DATETIME default CURRENT_TIMESTAMP not null,
    constraint address_snapshots_source_id_fk
        foreign key (source_id) references addresses (id)
);

create table user_addresses
(
    user_id       BINARY(16) not null,
    address_id    BIGINT     not null,
    constraint user_addresses_pk
        primary key (user_id, address_id),
    constraint user_addresses_addresses_id_fk
        foreign key (address_id) references addresses (id)
            on delete cascade,
    constraint user_addresses_users_id_fk
        foreign key (user_id) references users (id)
            on delete cascade
);

-- Products related --
create table orders
(
    id            BIGINT auto_increment not null
        primary key,
    user_id             BINARY(16)  not null,
    delivery_address_id BIGINT      not null,
    created_at          DATETIME default CURRENT_TIMESTAMP    not null,
    updated_at          DATETIME
        default CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP not null,
    order_status        VARCHAR(20) not null,
    constraint orders_user_id_fk
        foreign key (user_id) references users (id),
    constraint order_delivery_address_id
        foreign key (delivery_address_id) references address_snapshots (id)
);

create table products(
    id            BIGINT auto_increment not null
        primary key,
    name          VARCHAR(100) not null,
    description   TEXT,
    sku           VARCHAR(12) not null,
    price         DECIMAL(10,2) not null,
    constraint products_sku_uk
        unique (sku)
);

create table order_items
(
    id            BIGINT auto_increment not null
        primary key,
    order_id      BIGINT not null,
    product_id    BIGINT not null,
    unit_price    DECIMAL(10,2) not null,
    quantity      BIGINT not null,
    constraint order_items_order_id_product_id_uk
        unique (order_id,product_id),
    constraint order_items_order_id_fk
        foreign key (order_id) references orders (id)
            on delete cascade,
    constraint order_items_product_id_fk
        foreign key (product_id) references products (id)
);

-- Warehouse related --
create table locations
(
    id            BIGINT auto_increment              not null
        primary key,
    address_id    BIGINT       not null,
    name          VARCHAR(100) not null,
    status        VARCHAR(20)  not null,
    opened_at     DATETIME default CURRENT_TIMESTAMP not null,
    constraint locations_address_id_fk
        foreign key (address_id) references addresses (id)
);

create table warehouses
(
    id            BIGINT auto_increment              not null
        primary key,
    name          VARCHAR(100)  not null,
    location_id   BIGINT        not null,
    opened_at     DATETIME default CURRENT_TIMESTAMP not null,
    constraint warehouses_name_location_id_uk
        unique (name,location_id),
    constraint warehouses_location_id_fk
        foreign key (location_id) references locations (id)
);

-- Stock related --
create table inventory_records
(
    id                  BIGINT auto_increment                 not null
        primary key,
    product_id          BIGINT not null,
    warehouse_id        BIGINT not null,
    quantity_on_hand    BIGINT not null,
    quantity_reserved   BIGINT not null,
    updated_at          DATETIME
        default CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP not null,
    restock_threshold   BIGINT,
    constraint inventory_records_product_id_warehouse_id_uk
        unique (product_id,warehouse_id),
    constraint inventory_records_warehouses_id_fk
        foreign key (warehouse_id) references warehouses (id),
    constraint inventory_records_product_id_fk
        foreign key (product_id) references products (id),
    -- Constraints to prevent concurrents request to mess things up
    constraint inventory_records_quantity_on_hand_ck
        check (quantity_on_hand >= 0),
    constraint inventory_records_quantity_reserved_ck
        check (quantity_reserved >= 0 and quantity_reserved <= quantity_on_hand)
);

create table stock_movements
(
    id                   BIGINT auto_increment              not null
        primary key,
    inventory_records_id BIGINT         not null,
    operation_type       VARCHAR(30)    not null,
    quantity_involved    BIGINT         not null,
    created_at           DATETIME default CURRENT_TIMESTAMP not null,
    reference_type       VARCHAR(100)   not null,
    reference_id         BIGINT         not null,
    constraint stock_movements_inventory_records_id_created_at_uk
        unique (inventory_records_id,created_at),
    constraint stock_movements_inventory_records_id_fk
        foreign key (inventory_records_id) references inventory_records (id)
);

-- Restock Related --
create table suppliers
(
    id            BINARY(16) default (uuid_to_bin(uuid()))   not null
        primary key,
    name          VARCHAR(100) not null,
    created_at    DATETIME default CURRENT_TIMESTAMP         not null
);

create table restock_orders
(
    id                   BIGINT auto_increment              not null
        primary key,
    supplier_id          BINARY(16)                         not null,
    status               VARCHAR(20)                        not null,
    created_at           DATETIME default CURRENT_TIMESTAMP not null,
    delivered_at         DATETIME,
    constraint restock_orders_supplier_id_fk
        foreign key (supplier_id) references suppliers (id)
);

create table restock_order_items
(
    id                   BIGINT auto_increment              not null
        primary key,
    inventory_records_id  BIGINT         not null,
    restock_order_id     BIGINT         not null,
    unit_price           DECIMAL(10,2)  not null,
    quantity             BIGINT         not null,
    constraint restock_order_items_uk
        unique (inventory_records_id,restock_order_id),
    constraint restock_order_items_inventory_records_id_fk
        foreign key (inventory_records_id) references inventory_records (id),
    constraint restock_order_items_restock_order_id_fk
        foreign key (restock_order_id) references restock_orders (id)
            on delete cascade
);

-- Shipment related --
create table shipments
(
    id                   BIGINT auto_increment              not null
        primary key,
    ship_address_id      BIGINT         not null,
    shipment_status      VARCHAR(20)    not null,
    created_at           DATETIME default CURRENT_TIMESTAMP not null,
    closed_at            DATETIME,
    constraint shipments_ship_address_id_fk
        foreign key (ship_address_id) references address_snapshots (id)
);

create table shipment_items
(
    id                   BIGINT auto_increment              not null
        primary key,
    order_items_id       BIGINT not null,
    shipment_id          BIGINT not null,
    warehouse_id         BIGINT not null,
    quantity             BIGINT not null,
    constraint shipment_items_uk
        unique (order_items_id,shipment_id,warehouse_id),
    constraint shipment_items_order_items_id_fk
        foreign key (order_items_id) references order_items (id),
    constraint shipment_items_shipment_id_fk
        foreign key (shipment_id) references shipments (id)
            on delete cascade,
    constraint shipment_items_warehouse_id_fk
        foreign key (warehouse_id) references warehouses (id)
);

create table deliveries
(
    id                   BIGINT auto_increment              not null
        primary key,
    carrier_id           BINARY(16)     not null,
    shipment_id          BIGINT         not null,
    delivery_status      VARCHAR(20)    not null,
    created_at           DATETIME default CURRENT_TIMESTAMP not null,
    departed_at          DATETIME,
    delivered_at         DATETIME,
    constraint deliveries_carrier_id_fk
        foreign key (carrier_id) references users (id),
    constraint deliveries_shipment_id_fk
        foreign key (shipment_id) references shipments (id)
            on delete cascade
);