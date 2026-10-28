CREATE TABLE jsh_factory_product_material (
 tenant_id BIGINT NOT NULL,
 product_id BIGINT NOT NULL,
 version INT NOT NULL DEFAULT 1,
 lines_json MEDIUMTEXT NOT NULL,
 updated_by BIGINT NOT NULL,
 updated_at DATETIME NOT NULL,
 PRIMARY KEY(tenant_id,product_id)
);
