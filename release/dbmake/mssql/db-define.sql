-- ***************************************************************************
-- This script will handle all post db create statements on an Xstore database compatible with DB 
-- platform <platform> and, where applicable, create/assign the appropriate users, roles, and 
-- platform-specific options for it.
--
-- This script does not define any schematics for the new database.  To identify an Xstore-compatible
-- schema for it, run the "new" script designated for the desired application version.
--
-- Platform:  Microsoft SQL Server 2012/2014/2016
-- ***************************************************************************

use $(DbName);  -- If this is not the correct name for your database, please change it before executing this script.
GO

CREATE PROCEDURE Create_Property_Table
  -- Add the parameters for the stored procedure here
  @tableName varchar(30)
AS
BEGIN
  declare @sql varchar(max),
      @column varchar(30),
      @pk varchar(max),
      @datatype varchar(10),
      @maxlen varchar(4),
      @prec varchar(3),
      @scale varchar(3),
      @deflt varchar(50);
  SET NOCOUNT ON;

  IF OBJECT_ID(@tableName + '_p') IS NOT NULL or OBJECT_ID(@tableName) IS NULL or RIGHT(@tableName,2)='_p' or NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS C JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS K
  ON C.TABLE_NAME = K.TABLE_NAME AND C.CONSTRAINT_CATALOG = K.CONSTRAINT_CATALOG AND C.CONSTRAINT_SCHEMA = K.CONSTRAINT_SCHEMA AND C.CONSTRAINT_NAME = K.CONSTRAINT_NAME
  WHERE C.CONSTRAINT_TYPE = 'PRIMARY KEY' and K.TABLE_NAME = @tableName and K.COLUMN_NAME = 'organization_id')
    return;

  set @pk = '';
  set @sql='CREATE TABLE dbo.' + @tableName + '_p (
  '
    declare mycur CURSOR Fast_Forward FOR
  SELECT COL.COLUMN_NAME,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_SCALE,replace(replace(COLUMN_DEFAULT,'(',''),')','') FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS C JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS K
  ON C.TABLE_NAME = K.TABLE_NAME AND C.CONSTRAINT_CATALOG = K.CONSTRAINT_CATALOG AND C.CONSTRAINT_SCHEMA = K.CONSTRAINT_SCHEMA AND C.CONSTRAINT_NAME = K.CONSTRAINT_NAME
  join INFORMATION_SCHEMA.COLUMNS col ON C.TABLE_NAME=col.TABLE_NAME and K.COLUMN_NAME=COL.COLUMN_NAME
  WHERE C.CONSTRAINT_TYPE = 'PRIMARY KEY' and K.TABLE_NAME = @tableName
  order by K.ORDINAL_POSITION

  open mycur;

  while 1=1
  BEGIN
    FETCH NEXT FROM mycur INTO @column,@datatype,@maxlen,@prec,@scale,@deflt;
    IF @@FETCH_STATUS <> 0
      BREAK;

      set @pk=@pk + @column + ','

    set @sql=@sql + @column + ' ' + @datatype

    if @datatype='varchar' or @datatype='nvarchar' or @datatype='char' or @datatype='nchar'
      set @sql=@sql + '(' + @maxlen + ')'
    else if @datatype='numeric' or @datatype='decimal'
      set @sql=@sql + '(' + @prec + ',' + @scale + ')'

    if LEN(@deflt)>0
      set @sql=@sql + ' DEFAULT ' + @deflt

    set @sql=@sql + ' NOT NULL,
  '
  END
  close mycur
  deallocate mycur

  set @sql=@sql + 'property_code varchar(30) NOT NULL,
    type varchar(30) NULL,
    string_value varchar(4000) NULL,
    date_value datetime NULL,
    decimal_value decimal(17,6) NULL,
    create_date datetime NULL,
    create_user_id varchar(256) NULL,
    update_date datetime NULL,
    update_user_id varchar(256) NULL,
    record_state varchar(30) NULL,
  '

  if LEN('pk_'+ @tableName + '_p')>123
    set @sql=@sql + 'CONSTRAINT ' + REPLACE('pk_'+ @tableName + '_p','_','') + ' PRIMARY KEY CLUSTERED (' + @pk + 'property_code) WITH (FILLFACTOR = 80))'
  else
    set @sql=@sql + 'CONSTRAINT pk_'+ @tableName + '_p PRIMARY KEY CLUSTERED (' + @pk + 'property_code) WITH (FILLFACTOR = 80))'

  print '--- CREATING TABLE ' + @tableName + '_p ---'
  exec(@sql);
END
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT '--- CREATING cat_acct_note --- ';
CREATE TABLE dbo.cat_acct_note(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
note_seq BIGINT NOT NULL,
entry_timestamp DATETIME,
entry_party_id BIGINT,
note VARCHAR(MAX),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_acct_note PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id, note_seq))
GO
EXEC CREATE_PROPERTY_TABLE cat_acct_note;
GO
PRINT '--- CREATING cat_authorizations --- ';
CREATE TABLE dbo.cat_authorizations(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
status_code VARCHAR(30),
status_datetime DATETIME,
authorization_type VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_authorizations PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE cat_authorizations;
GO
PRINT '--- CREATING cat_award_acct --- ';
CREATE TABLE dbo.cat_award_acct(
organization_id INT NOT NULL,
cust_card_nbr VARCHAR(60) NOT NULL,
acct_id VARCHAR(60) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_award_acct PRIMARY KEY CLUSTERED (organization_id, cust_card_nbr, acct_id))
GO
EXEC CREATE_PROPERTY_TABLE cat_award_acct;
GO
PRINT '--- CREATING cat_award_acct_coupon --- ';
CREATE TABLE dbo.cat_award_acct_coupon(
organization_id INT NOT NULL,
cust_card_nbr VARCHAR(60) NOT NULL,
acct_id VARCHAR(60) NOT NULL,
coupon_id VARCHAR(60) NOT NULL,
amount DECIMAL(17, 6),
expiration_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_award_acct_coupon PRIMARY KEY CLUSTERED (organization_id, cust_card_nbr, acct_id, coupon_id))
GO
EXEC CREATE_PROPERTY_TABLE cat_award_acct_coupon;
GO
PRINT '--- CREATING cat_charge_acct_history --- ';
CREATE TABLE dbo.cat_charge_acct_history(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
history_seq BIGINT NOT NULL,
activity_date DATETIME,
activity_enum VARCHAR(30),
amt DECIMAL(17, 6),
party_id BIGINT,
acct_user_name VARCHAR(254),
business_date DATETIME,
trans_seq BIGINT,
rtrans_lineitm_seq INT,
rtl_loc_id INT,
wkstn_id BIGINT,
acct_balance DECIMAL(17, 6),
acct_user_id VARCHAR(30),
reversed_flag BIT DEFAULT (0) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_charge_acct_history PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id, history_seq))
GO
PRINT '--- CREATING IDX_CAT_CHARGE_ACCT_HIST01 --- ';
CREATE INDEX IDX_CAT_CHARGE_ACCT_HIST01 ON dbo.cat_charge_acct_history(party_id)
GO

EXEC CREATE_PROPERTY_TABLE cat_charge_acct_history;
GO
PRINT '--- CREATING cat_charge_acct_invoice --- ';
CREATE TABLE dbo.cat_charge_acct_invoice(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
invoice_number VARCHAR(60) NOT NULL,
invoice_balance DECIMAL(17, 6) NOT NULL,
original_invoice_balance DECIMAL(17, 6),
invoice_date DATETIME,
last_activity_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_charge_acct_invoice PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id, invoice_number))
GO
EXEC CREATE_PROPERTY_TABLE cat_charge_acct_invoice;
GO
PRINT '--- CREATING cat_charge_acct_users --- ';
CREATE TABLE dbo.cat_charge_acct_users(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
acct_user_id VARCHAR(30) NOT NULL,
acct_user_name VARCHAR(254) NOT NULL,
party_id BIGINT,
effective_date DATETIME,
expiration_date DATETIME,
primary_contact_flag BIT DEFAULT (0),
acct_user_first_name VARCHAR(60),
acct_user_last_name VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_charge_acct_users PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id, acct_user_id))
GO
PRINT '--- CREATING IDX_CAT_CHARGE_ACCT_USERS01 --- ';
CREATE INDEX IDX_CAT_CHARGE_ACCT_USERS01 ON dbo.cat_charge_acct_users(party_id)
GO

EXEC CREATE_PROPERTY_TABLE cat_charge_acct_users;
GO
PRINT '--- CREATING cat_cust_acct --- ';
CREATE TABLE dbo.cat_cust_acct(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
acct_balance DECIMAL(17, 6),
rtl_loc_id INT,
cust_identity_req_flag BIT DEFAULT (0),
cust_identity_typcode VARCHAR(30),
party_id BIGINT,
acct_po_nbr VARCHAR(60),
dtv_class_name VARCHAR(254),
cust_acct_statcode VARCHAR(30),
last_activity_date DATETIME,
acct_setup_date DATETIME,
first_name VARCHAR(254),
last_name VARCHAR(254),
telephone VARCHAR(32),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_cust_acct PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id))
GO
PRINT '--- CREATING XST_CAT_CUSTACCT_ID --- ';
CREATE INDEX XST_CAT_CUSTACCT_ID ON dbo.cat_cust_acct(cust_acct_id)
GO

PRINT '--- CREATING XST_CAT_CUSTACCT_PARTYID --- ';
CREATE INDEX XST_CAT_CUSTACCT_PARTYID ON dbo.cat_cust_acct(organization_id, party_id)
GO

EXEC CREATE_PROPERTY_TABLE cat_cust_acct;
GO
PRINT '--- CREATING cat_cust_acct_card --- ';
CREATE TABLE dbo.cat_cust_acct_card(
organization_id INT NOT NULL,
cust_acct_card_nbr VARCHAR(60) NOT NULL,
party_id BIGINT,
effective_date DATETIME,
expr_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_cust_acct_card PRIMARY KEY CLUSTERED (organization_id, cust_acct_card_nbr))
GO
EXEC CREATE_PROPERTY_TABLE cat_cust_acct_card;
GO
PRINT '--- CREATING cat_cust_acct_journal --- ';
CREATE TABLE dbo.cat_cust_acct_journal(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
journal_seq BIGINT NOT NULL,
rtl_loc_id INT,
party_id BIGINT,
acct_balance DECIMAL(17, 6),
cust_identity_typcode VARCHAR(30),
trans_rtl_loc_id INT,
trans_wkstn_id BIGINT,
trans_business_date DATETIME,
trans_trans_seq BIGINT,
dtv_class_name VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_cust_acct_journal PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id, journal_seq))
GO
PRINT '--- CREATING IDX_CAT_CUST_ACCT_JOURNAL01 --- ';
CREATE INDEX IDX_CAT_CUST_ACCT_JOURNAL01 ON dbo.cat_cust_acct_journal(party_id)
GO

EXEC CREATE_PROPERTY_TABLE cat_cust_acct_journal;
GO
PRINT '--- CREATING cat_cust_acct_plan --- ';
CREATE TABLE dbo.cat_cust_acct_plan(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
plan_id VARCHAR(30) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
plan_description VARCHAR(255),
effective_date DATETIME,
expiration_date DATETIME,
display_order INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_cust_acct_plan PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, plan_id))
GO
PRINT '--- CREATING IDX_CAT_CUST_ACCT_PLAN_ORGNODE --- ';
CREATE INDEX IDX_CAT_CUST_ACCT_PLAN_ORGNODE ON dbo.cat_cust_acct_plan(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE cat_cust_acct_plan;
GO
PRINT '--- CREATING cat_cust_consumer_charge_acct --- ';
CREATE TABLE dbo.cat_cust_consumer_charge_acct(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
credit_limit DECIMAL(17, 6),
po_req_flag BIT DEFAULT (0),
on_hold_flag BIT DEFAULT (0),
corporate_account_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_cust_consumer_charge_acct PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id))
GO
PRINT '--- CREATING cat_cust_item_acct --- ';
CREATE TABLE dbo.cat_cust_item_acct(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
acct_total DECIMAL(17, 6),
active_payment_amt DECIMAL(17, 6),
total_payment_amt DECIMAL(17, 6),
active_acct_total DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_cust_item_acct PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id))
GO
PRINT '--- CREATING cat_cust_item_acct_activity --- ';
CREATE TABLE dbo.cat_cust_item_acct_activity(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
cust_item_acct_detail_item_nbr INT NOT NULL,
seq_nbr INT NOT NULL,
activity_datetime DATETIME,
item_acct_activity_code VARCHAR(30),
item_acct_lineitm_statcode VARCHAR(30),
rtl_loc_id INT,
wkstn_id BIGINT,
business_date DATETIME,
trans_seq BIGINT,
rtrans_lineitm_seq INT,
unit_price DECIMAL(17, 6),
quantity DECIMAL(11, 4),
line_typcode VARCHAR(30),
extended_amt DECIMAL(17, 6),
net_amt DECIMAL(17, 6),
scheduled_pickup_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_cust_item_acct_activity PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id, cust_item_acct_detail_item_nbr, seq_nbr))
GO
PRINT '--- CREATING IDX_CAT_CUST_ITEM_ACCT_ACTVY01 --- ';
CREATE INDEX IDX_CAT_CUST_ITEM_ACCT_ACTVY01 ON dbo.cat_cust_item_acct_activity(organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq)
GO

EXEC CREATE_PROPERTY_TABLE cat_cust_item_acct_activity;
GO
PRINT '--- CREATING cat_cust_item_acct_detail --- ';
CREATE TABLE dbo.cat_cust_item_acct_detail(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
cust_item_acct_detail_item_nbr INT NOT NULL,
item_acct_lineitm_statcode VARCHAR(30),
original_item_add_date DATETIME,
rtl_loc_id INT,
wkstn_id BIGINT,
business_date DATETIME,
trans_seq BIGINT,
rtrans_lineitm_seq INT,
line_typcode VARCHAR(30),
extended_amt DECIMAL(17, 6),
net_amt DECIMAL(17, 6),
unit_price DECIMAL(17, 6),
quantity DECIMAL(11, 4),
scheduled_pickup_date DATETIME,
source_loc_id INT,
fullfillment_loc_id INT,
delivery_type_id VARCHAR(20),
received_by_cust_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_cust_item_acct_detail PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id, cust_item_acct_detail_item_nbr))
GO
EXEC CREATE_PROPERTY_TABLE cat_cust_item_acct_detail;
GO
PRINT '--- CREATING cat_cust_item_acct_journal --- ';
CREATE TABLE dbo.cat_cust_item_acct_journal(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
journal_seq BIGINT NOT NULL,
cust_acct_statcode VARCHAR(30),
acct_setup_date DATETIME,
last_activity_date DATETIME,
acct_total DECIMAL(17, 6),
active_payment_amt DECIMAL(17, 6),
active_acct_total DECIMAL(17, 6),
total_payment_amt DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_cust_item_acct_journal PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id, journal_seq))
GO
PRINT '--- CREATING cat_cust_loyalty_acct --- ';
CREATE TABLE dbo.cat_cust_loyalty_acct(
organization_id INT NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
cust_card_nbr VARCHAR(60) DEFAULT ('UNKNOWN') NOT NULL,
effective_date DATETIME,
expiration_date DATETIME,
acct_balance DECIMAL(17, 6),
escrow_balance DECIMAL(17, 6),
bonus_balance DECIMAL(17, 6),
loyalty_program_id VARCHAR(60),
loyalty_program_level_id VARCHAR(60),
loyalty_program_name VARCHAR(60),
loyalty_program_level_name VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_cust_loyalty_acct PRIMARY KEY CLUSTERED (organization_id, cust_acct_id, cust_card_nbr))
GO
EXEC CREATE_PROPERTY_TABLE cat_cust_loyalty_acct;
GO
PRINT '--- CREATING cat_delivery_modifier --- ';
CREATE TABLE dbo.cat_delivery_modifier(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
delivery_enum VARCHAR(30),
address1 VARCHAR(254),
address2 VARCHAR(254),
address3 VARCHAR(254),
address4 VARCHAR(254),
city VARCHAR(254),
state VARCHAR(30),
postal_code VARCHAR(30),
country VARCHAR(2),
neighborhood VARCHAR(254),
county VARCHAR(254),
telephone1 VARCHAR(32),
telephone2 VARCHAR(32),
telephone3 VARCHAR(32),
telephone4 VARCHAR(32),
apartment VARCHAR(30),
first_name VARCHAR(254),
middle_name VARCHAR(254),
last_name VARCHAR(254),
shipping_method VARCHAR(254),
tracking_number VARCHAR(254),
extension VARCHAR(8),
delivery_end_time DATETIME,
delivery_start_time DATETIME,
delivery_date DATETIME,
instructions VARCHAR(254),
geo_code VARCHAR(20),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_delivery_modifier PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id))
GO
EXEC CREATE_PROPERTY_TABLE cat_delivery_modifier;
GO
PRINT '--- CREATING cat_escrow_acct --- ';
CREATE TABLE dbo.cat_escrow_acct(
organization_id INT NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
acct_balance DECIMAL(17, 6),
cust_acct_statcode VARCHAR(30),
acct_setup_date DATETIME,
last_activity_date DATETIME,
party_id BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_escrow_acct PRIMARY KEY CLUSTERED (organization_id, cust_acct_id))
GO
EXEC CREATE_PROPERTY_TABLE cat_escrow_acct;
GO
PRINT '--- CREATING cat_escrow_acct_activity --- ';
CREATE TABLE dbo.cat_escrow_acct_activity(
organization_id INT NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
seq_nbr BIGINT NOT NULL,
activity_date DATETIME,
activity_enum VARCHAR(30),
amt DECIMAL(17, 6),
business_date DATETIME,
trans_seq BIGINT,
rtl_loc_id INT,
wkstn_id BIGINT,
source_cust_acct_id VARCHAR(60),
source_cust_acct_code VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_escrow_acct_activity PRIMARY KEY CLUSTERED (organization_id, cust_acct_id, seq_nbr))
GO
EXEC CREATE_PROPERTY_TABLE cat_escrow_acct_activity;
GO
PRINT '--- CREATING cat_payment_schedule --- ';
CREATE TABLE dbo.cat_payment_schedule(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
begin_date DATETIME,
interval_type_enum VARCHAR(30),
interval_count INT,
total_payment_amt DECIMAL(17, 6),
payment_count INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cat_payment_schedule PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id))
GO
EXEC CREATE_PROPERTY_TABLE cat_payment_schedule;
GO
PRINT '--- CREATING cfra_invoice_dup --- ';
CREATE TABLE dbo.cfra_invoice_dup(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
reprint_id VARCHAR(30) NOT NULL,
doc_number VARCHAR(30) NOT NULL,
reprint_number INT,
operator_code VARCHAR(30),
business_date DATETIME,
reprint_date DATETIME,
document_type VARCHAR(30),
inv_rtl_loc_id INT,
inv_wkstn_id BIGINT,
inv_business_year INT,
inv_sequence_id VARCHAR(255),
inv_sequence_nbr BIGINT,
postponement_flag BIT DEFAULT (0),
signature VARCHAR(1024),
signature_source VARCHAR(1024),
signature_version INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cfra_invoice_dup PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, reprint_id, doc_number))
GO
EXEC CREATE_PROPERTY_TABLE cfra_invoice_dup;
GO
PRINT '--- CREATING cfra_rcpt_dup --- ';
CREATE TABLE dbo.cfra_rcpt_dup(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
reprint_id VARCHAR(30) NOT NULL,
doc_number VARCHAR(30) NOT NULL,
reprint_number INT,
operator_code VARCHAR(30),
amount_lines INT,
business_date DATETIME,
reprint_date DATETIME,
postponement_flag BIT DEFAULT (0),
signature VARCHAR(1024),
signature_source VARCHAR(1024),
signature_version INT,
trans_rtl_loc_id INT,
trans_business_date DATETIME,
trans_wkstn_id BIGINT,
trans_trans_seq BIGINT,
document_type VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cfra_rcpt_dup PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, reprint_id, doc_number))
GO
EXEC CREATE_PROPERTY_TABLE cfra_rcpt_dup;
GO
PRINT '--- CREATING cfra_sales_tax_total --- ';
CREATE TABLE dbo.cfra_sales_tax_total(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
fiscal_year INT NOT NULL,
reference_year INT NOT NULL,
reference_month INT NOT NULL,
reference_day INT NOT NULL,
tax_rate INT NOT NULL,
sales_total DECIMAL(17, 6),
grand_total DECIMAL(17, 6),
sales_only_total DECIMAL(17, 6),
returns_only_total DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cfra_sales_tax_total PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, fiscal_year, reference_year, reference_month, reference_day, tax_rate))
GO
EXEC CREATE_PROPERTY_TABLE cfra_sales_tax_total;
GO
PRINT '--- CREATING cfra_sales_total --- ';
CREATE TABLE dbo.cfra_sales_total(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
fiscal_year INT NOT NULL,
reference_year INT NOT NULL,
reference_month INT NOT NULL,
reference_day INT NOT NULL,
fiscal_month INT,
status_code VARCHAR(30),
sales_total DECIMAL(17, 6),
grand_total DECIMAL(17, 6),
sales_only_total DECIMAL(17, 6),
returns_only_total DECIMAL(17, 6),
perpetual_grand_total DECIMAL(17, 6),
real_perpetual_grand_total DECIMAL(17, 6),
total_timestamp DATETIME,
postponement_flag BIT DEFAULT (0),
signature VARCHAR(1024),
signature_source VARCHAR(1024),
signature_version INT,
totals_file VARCHAR(MAX),
totals_file_sign VARCHAR(1024),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cfra_sales_total PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, fiscal_year, reference_year, reference_month, reference_day))
GO
EXEC CREATE_PROPERTY_TABLE cfra_sales_total;
GO
PRINT '--- CREATING cfra_sales_trn_tax_total --- ';
CREATE TABLE dbo.cfra_sales_trn_tax_total(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
reference_year INT NOT NULL,
reference_month INT NOT NULL,
reference_day INT NOT NULL,
document_number VARCHAR(30) NOT NULL,
tax_rate INT NOT NULL,
sales_only_total DECIMAL(17, 6),
returns_only_total DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cfra_sales_trn_tax_total PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, reference_year, reference_month, reference_day, document_number, tax_rate))
GO
EXEC CREATE_PROPERTY_TABLE cfra_sales_trn_tax_total;
GO
PRINT '--- CREATING cfra_sales_trn_total --- ';
CREATE TABLE dbo.cfra_sales_trn_total(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
reference_year INT NOT NULL,
reference_month INT NOT NULL,
reference_day INT NOT NULL,
document_number VARCHAR(30) NOT NULL,
sales_only_total DECIMAL(17, 6),
returns_only_total DECIMAL(17, 6),
daily_sales_total DECIMAL(17, 6),
perpetual_grand_total DECIMAL(17, 6),
real_perpetual_grand_total DECIMAL(17, 6),
trans_rtl_loc_id INT,
trans_business_date DATETIME,
trans_wkstn_id BIGINT,
trans_trans_seq BIGINT,
total_timestamp DATETIME,
postponement_flag BIT DEFAULT (0),
signature VARCHAR(1024),
signature_source VARCHAR(1024),
signature_version INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cfra_sales_trn_total PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, reference_year, reference_month, reference_day, document_number))
GO
EXEC CREATE_PROPERTY_TABLE cfra_sales_trn_total;
GO
PRINT '--- CREATING cfra_technical_event_log --- ';
CREATE TABLE dbo.cfra_technical_event_log(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
prefix VARCHAR(10) NOT NULL,
event_number INT NOT NULL,
unique_id VARCHAR(32),
event_code INT,
description VARCHAR(512),
operator_code VARCHAR(30),
event_timestamp DATETIME,
informations VARCHAR(MAX),
postponement_flag BIT DEFAULT (0),
signature VARCHAR(1024),
signature_source VARCHAR(4000),
signature_version INT,
business_date DATETIME NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cfra_technical_event_log PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, prefix, event_number))
GO
EXEC CREATE_PROPERTY_TABLE cfra_technical_event_log;
GO
PRINT '--- CREATING cger_tse_device --- ';
CREATE TABLE dbo.cger_tse_device(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
tse_seq INT NOT NULL,
tse_name VARCHAR(60),
tse_type VARCHAR(60),
tse_config VARCHAR(4000),
tse_admin_puk VARCHAR(60),
tse_admin_pin VARCHAR(60),
tse_time_pin VARCHAR(60),
tse_shared_key VARCHAR(60),
tse_serial_number VARCHAR(60),
tse_public_key VARCHAR(255),
tse_cert_expiry_date DATETIME,
tse_certificate VARCHAR(4000),
tse_signature_algo VARCHAR(60),
tse_date_format VARCHAR(60),
tse_pd_encoding VARCHAR(60),
tse_init_status VARCHAR(60),
tse_status VARCHAR(60),
void_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cger_tse_device PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, tse_seq))
GO
EXEC CREATE_PROPERTY_TABLE cger_tse_device;
GO
PRINT '--- CREATING cger_tse_device_register --- ';
CREATE TABLE dbo.cger_tse_device_register(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
tse_seq INT,
void_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cger_tse_device_register PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id))
GO
EXEC CREATE_PROPERTY_TABLE cger_tse_device_register;
GO
PRINT '--- CREATING civc_invoice --- ';
CREATE TABLE dbo.civc_invoice(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
business_year INT NOT NULL,
sequence_id VARCHAR(255) NOT NULL,
sequence_nbr BIGINT NOT NULL,
invoice_type VARCHAR(32) NOT NULL,
business_date DATETIME NOT NULL,
void_flag BIT DEFAULT (0),
party_id BIGINT NOT NULL,
ext_invoice_id VARCHAR(60),
gross_amt DECIMAL(17, 6),
refund_amt DECIMAL(17, 6),
invoice_date DATETIME,
ext_invoice_barcode VARCHAR(60),
return_flag BIT DEFAULT (0),
invoice_prefix VARCHAR(20),
confirm_flag BIT DEFAULT (0),
void_pending_flag BIT DEFAULT (0),
confirm_sent_flag BIT DEFAULT (0),
confirm_result VARCHAR(255),
time_stamp DATETIME,
document_number VARCHAR(60),
invoice_trans_seq BIGINT,
invoice_data VARBINARY(MAX),
invoice_export_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_civc_invoice PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, business_year, sequence_id, sequence_nbr))
GO
EXEC CREATE_PROPERTY_TABLE civc_invoice;
GO
PRINT '--- CREATING civc_invoice_xref --- ';
CREATE TABLE dbo.civc_invoice_xref(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
business_year INT NOT NULL,
sequence_id VARCHAR(255) NOT NULL,
sequence_nbr BIGINT NOT NULL,
trans_rtl_loc_id INT NOT NULL,
trans_business_date DATETIME NOT NULL,
trans_wkstn_id BIGINT NOT NULL,
trans_trans_seq BIGINT NOT NULL,
trans_trans_lineitm_seq INT NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_civc_invoice_xref PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, business_year, sequence_id, sequence_nbr, trans_rtl_loc_id, trans_business_date, trans_wkstn_id, trans_trans_seq, trans_trans_lineitm_seq))
GO
PRINT '--- CREATING IDX_CIVC_INVOICE_XREF_TRANS --- ';
CREATE INDEX IDX_CIVC_INVOICE_XREF_TRANS ON dbo.civc_invoice_xref(organization_id, trans_rtl_loc_id, trans_business_date, trans_wkstn_id, trans_trans_seq, trans_trans_lineitm_seq)
GO

EXEC CREATE_PROPERTY_TABLE civc_invoice_xref;
GO
PRINT '--- CREATING civc_taxfree_country --- ';
CREATE TABLE dbo.civc_taxfree_country(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
iso3num_code VARCHAR(3) NOT NULL,
iso2alp_code VARCHAR(2),
name VARCHAR(150),
phone_prefix VARCHAR(4),
passport_code VARCHAR(10),
void_flag BIT DEFAULT (0),
blocked_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_civc_taxfree_country PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, iso3num_code))
GO
EXEC CREATE_PROPERTY_TABLE civc_taxfree_country;
GO
PRINT '--- CREATING com_address --- ';
CREATE TABLE dbo.com_address(
organization_id INT NOT NULL,
address_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
address1 VARCHAR(254),
address2 VARCHAR(254),
address3 VARCHAR(254),
address4 VARCHAR(254),
apartment VARCHAR(30),
city VARCHAR(254),
territory VARCHAR(254),
postal_code VARCHAR(254),
country VARCHAR(2),
neighborhood VARCHAR(254),
county VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_address PRIMARY KEY CLUSTERED (organization_id, address_id))
GO
PRINT '--- CREATING IDX_COM_ADDRESS_ORGNODE --- ';
CREATE INDEX IDX_COM_ADDRESS_ORGNODE ON dbo.com_address(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE com_address;
GO
PRINT '--- CREATING com_address_country --- ';
CREATE TABLE dbo.com_address_country(
organization_id INT NOT NULL,
country_id VARCHAR(2) NOT NULL,
address_mode VARCHAR(60) DEFAULT ('DEFAULT') NOT NULL,
country_name VARCHAR(254),
max_postal_length INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_address_country PRIMARY KEY CLUSTERED (organization_id, country_id, address_mode))
GO
EXEC CREATE_PROPERTY_TABLE com_address_country;
GO
PRINT '--- CREATING com_address_postalcode --- ';
CREATE TABLE dbo.com_address_postalcode(
organization_id INT NOT NULL,
country_id VARCHAR(2) NOT NULL,
postal_code_id VARCHAR(30) NOT NULL,
address_mode VARCHAR(60) DEFAULT ('DEFAULT') NOT NULL,
state_id VARCHAR(10),
city_name VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_address_postalcode PRIMARY KEY CLUSTERED (organization_id, country_id, postal_code_id, address_mode))
GO
EXEC CREATE_PROPERTY_TABLE com_address_postalcode;
GO
PRINT '--- CREATING com_address_state --- ';
CREATE TABLE dbo.com_address_state(
organization_id INT NOT NULL,
country_id VARCHAR(2) NOT NULL,
state_id VARCHAR(10) NOT NULL,
address_mode VARCHAR(60) DEFAULT ('DEFAULT') NOT NULL,
state_name VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_address_state PRIMARY KEY CLUSTERED (organization_id, country_id, state_id, address_mode))
GO
EXEC CREATE_PROPERTY_TABLE com_address_state;
GO
PRINT '--- CREATING com_airport --- ';
CREATE TABLE dbo.com_airport(
organization_id INT NOT NULL,
airport_code VARCHAR(3) NOT NULL,
airport_name VARCHAR(254) NOT NULL,
country_code VARCHAR(2) NOT NULL,
zone_id VARCHAR(30) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_airport PRIMARY KEY CLUSTERED (organization_id, airport_code))
GO
EXEC CREATE_PROPERTY_TABLE com_airport;
GO
PRINT '--- CREATING com_airport_zone --- ';
CREATE TABLE dbo.com_airport_zone(
organization_id INT NOT NULL,
zone_id VARCHAR(30) NOT NULL,
description VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_airport_zone PRIMARY KEY CLUSTERED (organization_id, zone_id))
GO
EXEC CREATE_PROPERTY_TABLE com_airport_zone;
GO
PRINT '--- CREATING com_airport_zone_detail --- ';
CREATE TABLE dbo.com_airport_zone_detail(
organization_id INT NOT NULL,
zone_id VARCHAR(30) NOT NULL,
destination_zone_id VARCHAR(30) NOT NULL,
tax_calculation_mode VARCHAR(30) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_airport_zone_detail PRIMARY KEY CLUSTERED (organization_id, zone_id, destination_zone_id))
GO
EXEC CREATE_PROPERTY_TABLE com_airport_zone_detail;
GO
PRINT '--- CREATING com_broadcaster_options --- ';
CREATE TABLE dbo.com_broadcaster_options(
organization_id INT NOT NULL,
option_id INT NOT NULL,
translation_key VARCHAR(150) NOT NULL,
default_translation VARCHAR(255),
xpath VARCHAR(200),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_broadcaster_options PRIMARY KEY CLUSTERED (organization_id, option_id))
GO
EXEC CREATE_PROPERTY_TABLE com_broadcaster_options;
GO
PRINT '--- CREATING com_button_grid --- ';
CREATE TABLE dbo.com_button_grid(
organization_id INT NOT NULL,
level_code VARCHAR(30) DEFAULT ('*') NOT NULL,
level_value VARCHAR(60) DEFAULT ('*') NOT NULL,
grid_id VARCHAR(50) NOT NULL,
row_id INT NOT NULL,
column_id INT NOT NULL,
component_id VARCHAR(50) NOT NULL,
sort_order INT DEFAULT (0) NOT NULL,
child_id VARCHAR(50),
key_name VARCHAR(50),
data VARCHAR(100),
text VARCHAR(255),
text_x INT,
text_y INT,
image_filename VARCHAR(512),
image_x INT,
image_y INT,
visibility_rule VARCHAR(255),
height_span INT,
width_span INT,
background_rgb VARCHAR(7),
foreground_rgb VARCHAR(7),
button_style VARCHAR(50),
action_idx INT,
animation_idx INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_button_grid PRIMARY KEY CLUSTERED (organization_id, level_code, level_value, grid_id, row_id, column_id, component_id, sort_order))
GO
EXEC CREATE_PROPERTY_TABLE com_button_grid;
GO
PRINT '--- CREATING com_code_value --- ';
CREATE TABLE dbo.com_code_value(
organization_id INT NOT NULL,
category VARCHAR(30) NOT NULL,
code VARCHAR(60) NOT NULL,
description VARCHAR(254),
sort_order INT,
hidden_flag BIT DEFAULT (0),
rank INT,
image_url VARCHAR(254),
config_element VARCHAR(200) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_code_value PRIMARY KEY CLUSTERED (organization_id, category, code))
GO
EXEC CREATE_PROPERTY_TABLE com_code_value;
GO
PRINT '--- CREATING com_country_return_map --- ';
CREATE TABLE dbo.com_country_return_map(
organization_id INT NOT NULL,
purchased_from VARCHAR(2) NOT NULL,
return_to VARCHAR(2) NOT NULL,
disallow_cross_border_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_country_return_map PRIMARY KEY CLUSTERED (organization_id, purchased_from, return_to))
GO
EXEC CREATE_PROPERTY_TABLE com_country_return_map;
GO
PRINT '--- CREATING com_external_system_map --- ';
CREATE TABLE dbo.com_external_system_map(
system_id VARCHAR(10) NOT NULL,
system_cd VARCHAR(10) NOT NULL,
organization_id INT NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_external_system_map PRIMARY KEY CLUSTERED (system_id, organization_id))
GO
EXEC CREATE_PROPERTY_TABLE com_external_system_map;
GO
PRINT '--- CREATING com_flight_info --- ';
CREATE TABLE dbo.com_flight_info(
organization_id INT NOT NULL,
scheduled_date_time DATETIME NOT NULL,
origin_airport VARCHAR(3) NOT NULL,
flight_number VARCHAR(30) NOT NULL,
destination_airport VARCHAR(3) NOT NULL,
via_1_airport VARCHAR(3),
via_2_airport VARCHAR(3),
via_3_airport VARCHAR(3),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_flight_info PRIMARY KEY CLUSTERED (organization_id, scheduled_date_time, origin_airport, flight_number))
GO
EXEC CREATE_PROPERTY_TABLE com_flight_info;
GO
PRINT '--- CREATING com_measurement --- ';
CREATE TABLE dbo.com_measurement(
organization_id INT NOT NULL,
dimension VARCHAR(30) NOT NULL,
code VARCHAR(10) NOT NULL,
name VARCHAR(254) NOT NULL,
symbol VARCHAR(254) NOT NULL,
factor DECIMAL(21, 10) NOT NULL,
qty_scale INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_measurement PRIMARY KEY CLUSTERED (organization_id, dimension, code))
GO
EXEC CREATE_PROPERTY_TABLE com_measurement;
GO
PRINT '--- CREATING com_reason_code --- ';
CREATE TABLE dbo.com_reason_code(
organization_id INT NOT NULL,
reason_typcode VARCHAR(30) NOT NULL,
reason_code VARCHAR(30) NOT NULL,
description VARCHAR(254),
parent_code VARCHAR(30),
gl_acct_nbr VARCHAR(254),
minimum_amt DECIMAL(17, 6),
maximum_amt DECIMAL(17, 6),
comment_req VARCHAR(10),
cust_msg VARCHAR(254),
inv_action_code VARCHAR(30),
location_id VARCHAR(60),
bucket_id VARCHAR(60),
sort_order INT,
hidden_flag BIT DEFAULT (0),
config_element VARCHAR(200) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_reason_code PRIMARY KEY CLUSTERED (organization_id, reason_typcode, reason_code))
GO
EXEC CREATE_PROPERTY_TABLE com_reason_code;
GO
PRINT '--- CREATING com_receipt_text --- ';
CREATE TABLE dbo.com_receipt_text(
organization_id INT NOT NULL,
text_code VARCHAR(30) NOT NULL,
text_subcode VARCHAR(30) NOT NULL,
text_seq INT NOT NULL,
config_element VARCHAR(200) DEFAULT ('*') NOT NULL,
receipt_text VARCHAR(4000) NOT NULL,
effective_date DATETIME,
expiration_date DATETIME,
reformat_flag BIT DEFAULT (1),
line_format VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_receipt_text PRIMARY KEY CLUSTERED (organization_id, text_code, text_subcode, text_seq, config_element))
GO
EXEC CREATE_PROPERTY_TABLE com_receipt_text;
GO
PRINT '--- CREATING com_report_data --- ';
CREATE TABLE dbo.com_report_data(
organization_id INT NOT NULL,
owner_type_enum VARCHAR(30) NOT NULL,
owner_id VARCHAR(60) NOT NULL,
report_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
report_data VARBINARY(MAX),
delete_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_report_data PRIMARY KEY CLUSTERED (organization_id, owner_type_enum, owner_id, report_id))
GO
PRINT '--- CREATING IDX_COM_REPORT_DATA_ORGNODE --- ';
CREATE INDEX IDX_COM_REPORT_DATA_ORGNODE ON dbo.com_report_data(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE com_report_data;
GO
PRINT '--- CREATING com_report_lookup --- ';
CREATE TABLE dbo.com_report_lookup(
organization_id INT NOT NULL,
owner_type_enum VARCHAR(30) NOT NULL,
owner_id VARCHAR(60) NOT NULL,
report_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
report_url VARCHAR(254),
description VARCHAR(254),
record_type_enum VARCHAR(30),
record_creation_date DATETIME,
record_level_enum VARCHAR(30),
parent_report_id VARCHAR(60),
delete_flag BIT DEFAULT (0) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_report_lookup PRIMARY KEY CLUSTERED (organization_id, owner_type_enum, owner_id, report_id))
GO
PRINT '--- CREATING IDX_COM_REPORT_LOOKUP_ORGNODE --- ';
CREATE INDEX IDX_COM_REPORT_LOOKUP_ORGNODE ON dbo.com_report_lookup(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE com_report_lookup;
GO
PRINT '--- CREATING com_sequence --- ';
CREATE TABLE dbo.com_sequence(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
sequence_id VARCHAR(255) NOT NULL,
sequence_mode VARCHAR(30) DEFAULT ('ACTIVE') NOT NULL,
sequence_nbr BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_sequence PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, sequence_id, sequence_mode))
GO
EXEC CREATE_PROPERTY_TABLE com_sequence;
GO
PRINT '--- CREATING com_sequence_journal --- ';
CREATE TABLE dbo.com_sequence_journal(
organization_id INT,
rtl_loc_id INT,
wkstn_id BIGINT,
sequence_id VARCHAR(255),
sequence_mode VARCHAR(30) DEFAULT ('ACTIVE'),
sequence_value VARCHAR(60),
sequence_timestamp DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30))
GO
EXEC CREATE_PROPERTY_TABLE com_sequence_journal;
GO
PRINT '--- CREATING com_sequence_part --- ';
CREATE TABLE dbo.com_sequence_part(
organization_id INT NOT NULL,
sequence_id VARCHAR(255) NOT NULL,
prefix VARCHAR(30),
suffix VARCHAR(30),
encode_flag BIT,
check_digit_algo VARCHAR(30),
numeric_flag BIT,
pad_length INT,
pad_character VARCHAR(2),
initial_value INT,
max_value INT,
value_increment INT,
include_store_id BIT,
store_pad_length INT,
include_wkstn_id BIT,
wkstn_pad_length INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_sequence_part PRIMARY KEY CLUSTERED (organization_id, sequence_id))
GO
EXEC CREATE_PROPERTY_TABLE com_sequence_part;
GO
PRINT '--- CREATING com_shipping_cost --- ';
CREATE TABLE dbo.com_shipping_cost(
organization_id INT NOT NULL,
begin_range DECIMAL(11, 2) NOT NULL,
end_range DECIMAL(11, 2) NOT NULL,
cost DECIMAL(17, 6) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
category VARCHAR(30) NOT NULL,
minimum_cost DECIMAL(17, 6),
maximum_cost DECIMAL(17, 6),
item_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_shipping_cost PRIMARY KEY CLUSTERED (organization_id, begin_range, end_range, cost, category))
GO
PRINT '--- CREATING IDX_COM_SHIPPING_COST_ORGNODE --- ';
CREATE INDEX IDX_COM_SHIPPING_COST_ORGNODE ON dbo.com_shipping_cost(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE com_shipping_cost;
GO
PRINT '--- CREATING com_shipping_fee --- ';
CREATE TABLE dbo.com_shipping_fee(
organization_id INT NOT NULL,
rule_name VARCHAR(30) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
priority INT,
ship_item_id VARCHAR(60),
aggregation_type VARCHAR(30),
rule_type VARCHAR(30),
param1 VARCHAR(30),
param2 VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_shipping_fee PRIMARY KEY CLUSTERED (organization_id, rule_name))
GO
PRINT '--- CREATING IDX_COM_SHIPPING_FEE_ORGNODE --- ';
CREATE INDEX IDX_COM_SHIPPING_FEE_ORGNODE ON dbo.com_shipping_fee(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE com_shipping_fee;
GO
PRINT '--- CREATING com_shipping_fee_tier --- ';
CREATE TABLE dbo.com_shipping_fee_tier(
organization_id INT NOT NULL,
rule_name VARCHAR(30) NOT NULL,
parent_rule_name VARCHAR(30) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
priority INT,
fee_type VARCHAR(20),
fee_value DECIMAL(17, 6),
ship_method VARCHAR(60),
min_price DECIMAL(17, 6),
max_price DECIMAL(17, 6),
item_id VARCHAR(60),
rule_type VARCHAR(30),
param1 VARCHAR(30),
param2 VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_shipping_fee_tier PRIMARY KEY CLUSTERED (organization_id, rule_name, parent_rule_name))
GO
PRINT '--- CREATING XST_COM_SHIP_TIER_SHIP_METHOD --- ';
CREATE INDEX XST_COM_SHIP_TIER_SHIP_METHOD ON dbo.com_shipping_fee_tier(ship_method)
GO

PRINT '--- CREATING IDX_COMSHIPPINGFEETIERORGNODE --- ';
CREATE INDEX IDX_COMSHIPPINGFEETIERORGNODE ON dbo.com_shipping_fee_tier(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE com_shipping_fee_tier;
GO
PRINT '--- CREATING com_signature --- ';
CREATE TABLE dbo.com_signature(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
signature_id VARCHAR(255) NOT NULL,
signature_mode VARCHAR(30) DEFAULT ('ACTIVE') NOT NULL,
signature_string VARCHAR(1024),
signature_source VARCHAR(4000),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_signature PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, signature_id, signature_mode))
GO
EXEC CREATE_PROPERTY_TABLE com_signature;
GO
PRINT '--- CREATING com_trans_prompt_properties --- ';
CREATE TABLE dbo.com_trans_prompt_properties(
organization_id INT NOT NULL,
trans_prompt_property_code VARCHAR(30) NOT NULL,
effective_date DATETIME NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
expiration_date DATETIME,
code_category VARCHAR(30),
prompt_title_key VARCHAR(60),
prompt_msg_key VARCHAR(60),
required_flag BIT DEFAULT (0),
sort_order INT,
prompt_mthd_code VARCHAR(30),
prompt_edit_pattern VARCHAR(30),
validation_rule_key VARCHAR(30),
transaction_state VARCHAR(30),
prompt_key VARCHAR(30),
chain_key VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_trans_prompt_properties PRIMARY KEY CLUSTERED (organization_id, trans_prompt_property_code, effective_date))
GO
PRINT '--- CREATING IDXCOMTRNSPRMPTPRPRTIESORGNODE --- ';
CREATE INDEX IDXCOMTRNSPRMPTPRPRTIESORGNODE ON dbo.com_trans_prompt_properties(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE com_trans_prompt_properties;
GO
PRINT '--- CREATING com_translations --- ';
CREATE TABLE dbo.com_translations(
organization_id INT NOT NULL,
locale VARCHAR(30) NOT NULL,
translation_key VARCHAR(150) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
translation VARCHAR(4000),
external_system VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_com_translations PRIMARY KEY CLUSTERED (organization_id, locale, translation_key))
GO
PRINT '--- CREATING IDX_COM_TRANSLATIONS_ORGNODE --- ';
CREATE INDEX IDX_COM_TRANSLATIONS_ORGNODE ON dbo.com_translations(org_code, org_value)
GO

PRINT '--- CREATING IDX_COM_TRANSLATIONS_ORG_KEY --- ';
CREATE INDEX IDX_COM_TRANSLATIONS_ORG_KEY ON dbo.com_translations(organization_id, translation_key)
GO

EXEC CREATE_PROPERTY_TABLE com_translations;
GO
PRINT '--- CREATING cpaf_address_muni --- ';
CREATE TABLE dbo.cpaf_address_muni(
organization_id INT NOT NULL,
municipality_id INT NOT NULL,
uf VARCHAR(2),
name VARCHAR(72),
ibge_code VARCHAR(7),
postal_code_start VARCHAR(8),
postal_code_end VARCHAR(8),
parent_municipality_id INT,
loc_in_sit VARCHAR(1),
loc_in_tipo_loc VARCHAR(1),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_address_muni PRIMARY KEY CLUSTERED (organization_id, municipality_id))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_address_muni;
GO
PRINT '--- CREATING cpaf_card_network --- ';
CREATE TABLE dbo.cpaf_card_network(
organization_id INT NOT NULL,
network_name VARCHAR(254) NOT NULL,
network_id VARCHAR(30),
tax_id VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_card_network PRIMARY KEY CLUSTERED (organization_id, network_name))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_card_network;
GO
PRINT '--- CREATING cpaf_nfe --- ';
CREATE TABLE dbo.cpaf_nfe(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
environment_id INT NOT NULL,
tp_nf INT NOT NULL,
series_id INT NOT NULL,
nnf INT NOT NULL,
model VARCHAR(2) NOT NULL,
cuf INT,
cnf INT,
trans_typcode VARCHAR(30),
natop VARCHAR(60),
indpag INT,
issue_date DATETIME,
sai_ent_datetime DATETIME,
cmun_fg VARCHAR(7),
tp_imp INT,
tp_emis INT,
fin_nfe INT,
proc_emi INT,
ver_proc VARCHAR(20),
cont_datetime DATETIME,
cont_xjust VARCHAR(255),
product_amount DECIMAL(17, 6),
service_amount DECIMAL(17, 6),
icms_basis DECIMAL(17, 6),
icms_amount DECIMAL(17, 6),
icms_st_basis DECIMAL(17, 6),
icms_st_amount DECIMAL(17, 6),
iss_basis DECIMAL(17, 6),
iss_amount DECIMAL(17, 6),
ii_amount DECIMAL(17, 6),
pis_amount DECIMAL(17, 6),
cofins_amount DECIMAL(17, 6),
iss_pis_amount DECIMAL(17, 6),
iss_cofins_amount DECIMAL(17, 6),
discount_amount DECIMAL(17, 6),
freight_amount DECIMAL(17, 6),
insurance_amount DECIMAL(17, 6),
other_amount DECIMAL(17, 6),
total_amount DECIMAL(17, 6),
inf_cpl VARCHAR(MAX),
protocolo VARCHAR(30),
canc_protocolo VARCHAR(30),
chave_nfe VARCHAR(88),
old_chave_nfe VARCHAR(88),
recibo VARCHAR(30),
stat_code VARCHAR(30),
xml VARCHAR(MAX),
dig_val VARCHAR(30),
iss_service_date VARCHAR(10),
fcp_amount DECIMAL(17, 6),
fcp_st_amount DECIMAL(17, 6),
fcp_st_ret_amount DECIMAL(17, 6),
v_troco_amount DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, environment_id, tp_nf, series_id, nnf, model))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe;
GO
PRINT '--- CREATING cpaf_nfe_dest --- ';
CREATE TABLE dbo.cpaf_nfe_dest(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
environment_id INT NOT NULL,
tp_nf INT NOT NULL,
series_id INT NOT NULL,
nnf INT NOT NULL,
model VARCHAR(2) NOT NULL,
name VARCHAR(60),
federal_tax_id VARCHAR(20),
state_tax_id VARCHAR(20),
street_name VARCHAR(60),
street_num VARCHAR(60),
complemento VARCHAR(60),
neighborhood VARCHAR(60),
city_code VARCHAR(7),
city VARCHAR(60),
state VARCHAR(30),
postal_code VARCHAR(8),
country_code VARCHAR(4),
country_name VARCHAR(60),
telephone VARCHAR(14),
email VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_dest PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, environment_id, tp_nf, series_id, nnf, model))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_dest;
GO
PRINT '--- CREATING cpaf_nfe_issuer --- ';
CREATE TABLE dbo.cpaf_nfe_issuer(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
environment_id INT NOT NULL,
tp_nf INT NOT NULL,
series_id INT NOT NULL,
nnf INT NOT NULL,
model VARCHAR(2) NOT NULL,
name VARCHAR(60),
fantasy_name VARCHAR(60),
federal_tax_id VARCHAR(20),
state_tax_id VARCHAR(20),
city_tax_id VARCHAR(20),
crt VARCHAR(1),
street_name VARCHAR(60),
street_num VARCHAR(60),
complemento VARCHAR(60),
neighborhood VARCHAR(60),
city_code VARCHAR(7),
city VARCHAR(60),
state VARCHAR(30),
postal_code VARCHAR(8),
country_code VARCHAR(4),
country_name VARCHAR(60),
telephone VARCHAR(14),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_issuer PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, environment_id, tp_nf, series_id, nnf, model))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_issuer;
GO
PRINT '--- CREATING cpaf_nfe_item --- ';
CREATE TABLE dbo.cpaf_nfe_item(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
environment_id INT NOT NULL,
tp_nf INT NOT NULL,
series_id INT NOT NULL,
nnf INT NOT NULL,
model VARCHAR(2) NOT NULL,
sequence INT NOT NULL,
item_id VARCHAR(60),
item_description VARCHAR(254),
ean VARCHAR(14),
ncm VARCHAR(8),
cest VARCHAR(18),
ex_tipi VARCHAR(3),
quantity DECIMAL(11, 4),
unit_of_measure_code VARCHAR(30),
taxable_ean VARCHAR(14),
taxable_unit_of_measure_code VARCHAR(30),
iat VARCHAR(1),
ippt VARCHAR(1),
unit_price DECIMAL(17, 6),
extended_amount DECIMAL(17, 6),
taxable_quantity DECIMAL(11, 4),
unit_taxable_amount DECIMAL(17, 6),
freight_amount DECIMAL(17, 6),
insurance_amount DECIMAL(17, 6),
discount_amount DECIMAL(17, 6),
other_amount DECIMAL(17, 6),
cfop VARCHAR(4),
inf_ad_prod VARCHAR(500),
icms_cst VARCHAR(3),
icms_basis DECIMAL(17, 6),
icms_amount DECIMAL(17, 6),
icms_rate DECIMAL(5, 2),
icms_st_basis DECIMAL(17, 6),
icms_st_amount DECIMAL(17, 6),
icms_st_rate DECIMAL(5, 2),
red_bc_efet_rate DECIMAL(5, 2),
bc_efet_amount DECIMAL(17, 6),
icms_efet_rate DECIMAL(5, 2),
icms_efet_amount DECIMAL(17, 6),
iss_basis DECIMAL(17, 6),
iss_amount DECIMAL(17, 6),
iss_rate DECIMAL(5, 2),
ipi_amount DECIMAL(17, 6),
ipi_rate DECIMAL(5, 2),
ii_amount DECIMAL(17, 6),
pis_basis DECIMAL(17, 6),
pis_amount DECIMAL(17, 6),
pis_rate DECIMAL(17, 6),
cofins_basis DECIMAL(17, 6),
cofins_amount DECIMAL(17, 6),
cofins_rate DECIMAL(17, 6),
tax_situation_code VARCHAR(6),
tax_group_id VARCHAR(120),
log_sequence INT,
ref_nfe VARCHAR(88),
iis_city_code VARCHAR(7),
iis_service_code VARCHAR(5),
iis_eligible_indicator VARCHAR(2),
iis_incentive_indicator VARCHAR(1),
st_rate DECIMAL(17, 6),
fcp_basis DECIMAL(17, 6),
fcp_amount DECIMAL(17, 6),
fcp_rate DECIMAL(17, 6),
fcp_st_basis DECIMAL(17, 6),
fcp_st_amount DECIMAL(17, 6),
fcp_st_rate DECIMAL(17, 6),
fcp_st_ret_basis DECIMAL(17, 6),
fcp_st_ret_amount DECIMAL(17, 6),
fcp_st_ret_rate DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_item PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, environment_id, tp_nf, series_id, nnf, model, sequence))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_item;
GO
PRINT '--- CREATING cpaf_nfe_queue --- ';
CREATE TABLE dbo.cpaf_nfe_queue(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
queue_seq INT NOT NULL,
environment_id INT,
tp_nf INT,
series_id INT,
nnf INT,
cuf INT,
cnf INT,
usage_type VARCHAR(30),
trans_typcode VARCHAR(30),
natop VARCHAR(60),
indpag INT,
model VARCHAR(2),
issue_date DATETIME,
sai_ent_datetime DATETIME,
cmun_fg VARCHAR(7),
tp_imp INT,
tp_emis INT,
fin_nfe INT,
proc_emi INT,
ver_proc VARCHAR(20),
cont_datetime DATETIME,
cont_xjust VARCHAR(255),
product_amount DECIMAL(17, 6),
service_amount DECIMAL(17, 6),
icms_basis DECIMAL(17, 6),
icms_amount DECIMAL(17, 6),
icms_st_basis DECIMAL(17, 6),
icms_st_amount DECIMAL(17, 6),
iss_basis DECIMAL(17, 6),
iss_amount DECIMAL(17, 6),
ii_amount DECIMAL(17, 6),
pis_amount DECIMAL(17, 6),
cofins_amount DECIMAL(17, 6),
iss_pis_amount DECIMAL(17, 6),
iss_cofins_amount DECIMAL(17, 6),
discount_amount DECIMAL(17, 6),
freight_amount DECIMAL(17, 6),
insurance_amount DECIMAL(17, 6),
other_amount DECIMAL(17, 6),
total_amount DECIMAL(17, 6),
inf_cpl VARCHAR(MAX),
protocolo VARCHAR(30),
canc_protocolo VARCHAR(30),
chave_nfe VARCHAR(88),
old_chave_nfe VARCHAR(88),
recibo VARCHAR(30),
stat_code VARCHAR(30),
xml VARCHAR(MAX),
response_code VARCHAR(30),
response_text VARCHAR(MAX),
dig_val VARCHAR(30),
iss_service_date VARCHAR(10),
fcp_amount DECIMAL(17, 6),
fcp_st_amount DECIMAL(17, 6),
fcp_st_ret_amount DECIMAL(17, 6),
v_troco_amount DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_queue PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, queue_seq))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_queue;
GO
PRINT '--- CREATING cpaf_nfe_queue_dest --- ';
CREATE TABLE dbo.cpaf_nfe_queue_dest(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
queue_seq INT NOT NULL,
name VARCHAR(60),
federal_tax_id VARCHAR(20),
state_tax_id VARCHAR(20),
street_name VARCHAR(60),
street_num VARCHAR(60),
complemento VARCHAR(60),
neighborhood VARCHAR(60),
city_code VARCHAR(7),
city VARCHAR(60),
state VARCHAR(30),
postal_code VARCHAR(8),
country_code VARCHAR(4),
country_name VARCHAR(60),
telephone VARCHAR(14),
email VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_queue_dest PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, queue_seq))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_queue_dest;
GO
PRINT '--- CREATING cpaf_nfe_queue_issuer --- ';
CREATE TABLE dbo.cpaf_nfe_queue_issuer(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
queue_seq INT NOT NULL,
name VARCHAR(60),
fantasy_name VARCHAR(60),
federal_tax_id VARCHAR(20),
state_tax_id VARCHAR(20),
city_tax_id VARCHAR(20),
crt VARCHAR(1),
street_name VARCHAR(60),
street_num VARCHAR(60),
complemento VARCHAR(60),
neighborhood VARCHAR(60),
city_code VARCHAR(7),
city VARCHAR(60),
state VARCHAR(30),
postal_code VARCHAR(8),
country_code VARCHAR(4),
country_name VARCHAR(60),
telephone VARCHAR(14),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_queue_issuer PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, queue_seq))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_queue_issuer;
GO
PRINT '--- CREATING cpaf_nfe_queue_item --- ';
CREATE TABLE dbo.cpaf_nfe_queue_item(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
queue_seq INT NOT NULL,
sequence INT NOT NULL,
item_id VARCHAR(60),
item_description VARCHAR(254),
ean VARCHAR(14),
ncm VARCHAR(8),
cest VARCHAR(18),
ex_tipi VARCHAR(3),
quantity DECIMAL(11, 4),
unit_of_measure_code VARCHAR(30),
taxable_ean VARCHAR(14),
taxable_unit_of_measure_code VARCHAR(30),
iat VARCHAR(1),
ippt VARCHAR(1),
unit_price DECIMAL(17, 6),
extended_amount DECIMAL(17, 6),
taxable_quantity DECIMAL(11, 4),
unit_taxable_amount DECIMAL(17, 6),
freight_amount DECIMAL(17, 6),
insurance_amount DECIMAL(17, 6),
discount_amount DECIMAL(17, 6),
other_amount DECIMAL(17, 6),
cfop VARCHAR(4),
inf_ad_prod VARCHAR(500),
icms_cst VARCHAR(3),
icms_basis DECIMAL(17, 6),
icms_amount DECIMAL(17, 6),
icms_rate DECIMAL(5, 2),
icms_st_basis DECIMAL(17, 6),
icms_st_amount DECIMAL(17, 6),
icms_st_rate DECIMAL(5, 2),
red_bc_efet_rate DECIMAL(5, 2),
bc_efet_amount DECIMAL(17, 6),
icms_efet_rate DECIMAL(5, 2),
icms_efet_amount DECIMAL(17, 6),
iss_basis DECIMAL(17, 6),
iss_amount DECIMAL(17, 6),
iss_rate DECIMAL(5, 2),
ipi_amount DECIMAL(17, 6),
ipi_rate DECIMAL(5, 2),
ii_amount DECIMAL(17, 6),
pis_basis DECIMAL(17, 6),
pis_amount DECIMAL(17, 6),
pis_rate DECIMAL(17, 6),
cofins_basis DECIMAL(17, 6),
cofins_amount DECIMAL(17, 6),
cofins_rate DECIMAL(17, 6),
tax_situation_code VARCHAR(6),
tax_group_id VARCHAR(120),
log_sequence INT,
ref_nfe VARCHAR(88),
iis_city_code VARCHAR(7),
iis_service_code VARCHAR(5),
iis_eligible_indicator VARCHAR(2),
iis_incentive_indicator VARCHAR(1),
st_rate DECIMAL(17, 6),
fcp_basis DECIMAL(17, 6),
fcp_amount DECIMAL(17, 6),
fcp_rate DECIMAL(17, 6),
fcp_st_basis DECIMAL(17, 6),
fcp_st_amount DECIMAL(17, 6),
fcp_st_rate DECIMAL(17, 6),
fcp_st_ret_basis DECIMAL(17, 6),
fcp_st_ret_amount DECIMAL(17, 6),
fcp_st_ret_rate DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_queue_item PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, queue_seq, sequence))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_queue_item;
GO
PRINT '--- CREATING cpaf_nfe_queue_log --- ';
CREATE TABLE dbo.cpaf_nfe_queue_log(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
queue_seq INT NOT NULL,
sequence INT NOT NULL,
stat_code VARCHAR(30),
response_code VARCHAR(30),
response_text VARCHAR(MAX),
source VARCHAR(255),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_queue_log PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, queue_seq, sequence))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_queue_log;
GO
PRINT '--- CREATING cpaf_nfe_queue_tender --- ';
CREATE TABLE dbo.cpaf_nfe_queue_tender(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
queue_seq INT NOT NULL,
sequence INT NOT NULL,
tndr_id VARCHAR(60) NOT NULL,
fiscal_tender_id VARCHAR(60) NOT NULL,
amount DECIMAL(17, 6),
card_network_id VARCHAR(30),
card_tax_id VARCHAR(30),
card_auth_number VARCHAR(254),
card_type VARCHAR(254),
card_trace_number VARCHAR(254),
card_integration_mode VARCHAR(30),
card_installments INT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_queue_tender PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, queue_seq, sequence, tndr_id))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_queue_tender;
GO
PRINT '--- CREATING cpaf_nfe_queue_trans --- ';
CREATE TABLE dbo.cpaf_nfe_queue_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
business_date DATETIME NOT NULL,
trans_seq INT NOT NULL,
trans_wkstn_id INT DEFAULT (1) NOT NULL,
queue_seq INT NOT NULL,
inactive_flag BIT DEFAULT (0) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_queue_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq, trans_wkstn_id, queue_seq))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_queue_trans;
GO
PRINT '--- CREATING cpaf_nfe_tax_cst --- ';
CREATE TABLE dbo.cpaf_nfe_tax_cst(
organization_id INT NOT NULL,
trans_typcode VARCHAR(30) NOT NULL,
tax_loc_id VARCHAR(60) NOT NULL,
tax_group_id VARCHAR(120) NOT NULL,
tax_authority_id VARCHAR(60) NOT NULL,
cst VARCHAR(2),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_tax_cst PRIMARY KEY CLUSTERED (organization_id, trans_typcode, tax_loc_id, tax_group_id, tax_authority_id))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_tax_cst;
GO
PRINT '--- CREATING cpaf_nfe_tender --- ';
CREATE TABLE dbo.cpaf_nfe_tender(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
environment_id INT NOT NULL,
tp_nf INT NOT NULL,
series_id INT NOT NULL,
nnf INT NOT NULL,
model VARCHAR(2) NOT NULL,
sequence INT NOT NULL,
tndr_id VARCHAR(60) NOT NULL,
fiscal_tender_id VARCHAR(60) NOT NULL,
amount DECIMAL(17, 6),
card_network_id VARCHAR(30),
card_tax_id VARCHAR(30),
card_auth_number VARCHAR(254),
card_type VARCHAR(254),
card_trace_number VARCHAR(254),
card_integration_mode VARCHAR(30),
card_installments INT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_tender PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, environment_id, tp_nf, series_id, nnf, model, sequence, tndr_id))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_tender;
GO
PRINT '--- CREATING cpaf_nfe_trans --- ';
CREATE TABLE dbo.cpaf_nfe_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
environment_id INT NOT NULL,
tp_nf INT NOT NULL,
series_id INT NOT NULL,
nnf INT NOT NULL,
model VARCHAR(2) NOT NULL,
business_date DATETIME NOT NULL,
trans_wkstn_id INT DEFAULT (1) NOT NULL,
trans_seq INT NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, environment_id, tp_nf, series_id, nnf, model, business_date, trans_wkstn_id, trans_seq))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_trans;
GO
PRINT '--- CREATING cpaf_nfe_trans_tax --- ';
CREATE TABLE dbo.cpaf_nfe_trans_tax(
organization_id INT NOT NULL,
trans_typcode VARCHAR(30) NOT NULL,
uf VARCHAR(2) NOT NULL,
dest_uf VARCHAR(2) NOT NULL,
tax_group_id VARCHAR(120) NOT NULL,
new_tax_group_id VARCHAR(120),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_trans_tax PRIMARY KEY CLUSTERED (organization_id, trans_typcode, uf, dest_uf, tax_group_id))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_trans_tax;
GO
PRINT '--- CREATING cpaf_nfe_trans_type --- ';
CREATE TABLE dbo.cpaf_nfe_trans_type(
organization_id INT NOT NULL,
trans_typcode VARCHAR(30) NOT NULL,
description VARCHAR(60),
notes VARCHAR(2000),
cfop_same_uf VARCHAR(4),
cfop_other_uf VARCHAR(4),
cfop_foreign VARCHAR(4),
fin_nfe INT DEFAULT (0),
display_order INT,
comment_req_flag BIT DEFAULT (0),
rule_type VARCHAR(30),
disallow_cancel_flag BIT DEFAULT (0),
pricing_type VARCHAR(30),
initial_comment VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_trans_type PRIMARY KEY CLUSTERED (organization_id, trans_typcode))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_trans_type;
GO
PRINT '--- CREATING cpaf_nfe_trans_type_use --- ';
CREATE TABLE dbo.cpaf_nfe_trans_type_use(
organization_id INT NOT NULL,
trans_typcode VARCHAR(30) NOT NULL,
usage_typcode VARCHAR(30) NOT NULL,
uf VARCHAR(2) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_nfe_trans_type_use PRIMARY KEY CLUSTERED (organization_id, trans_typcode, usage_typcode, uf))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_nfe_trans_type_use;
GO
PRINT '--- CREATING cpaf_sat_response --- ';
CREATE TABLE dbo.cpaf_sat_response(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
queue_seq INT NOT NULL,
session_id INT NOT NULL,
code_sate VARCHAR(32),
message_sate VARCHAR(254),
code_alert VARCHAR(32),
message_alert VARCHAR(254),
xml_string VARCHAR(MAX),
time_stamp DATETIME,
chave VARCHAR(254),
total_amount DECIMAL(17, 6),
cpf_cnpj_value VARCHAR(32),
signature_qr_code VARCHAR(2000),
success BIT,
timeout BIT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpaf_sat_response PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, queue_seq, session_id))
GO
EXEC CREATE_PROPERTY_TABLE cpaf_sat_response;
GO
PRINT '--- CREATING cpor_ats --- ';
CREATE TABLE dbo.cpor_ats(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
sequence_id VARCHAR(255) NOT NULL,
series VARCHAR(1) NOT NULL,
year BIGINT NOT NULL,
ats VARCHAR(70),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cpor_ats PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, sequence_id, series, year))
GO
EXEC CREATE_PROPERTY_TABLE cpor_ats;
GO
PRINT '--- CREATING crm_consent_info --- ';
CREATE TABLE dbo.crm_consent_info(
organization_id INT NOT NULL,
effective_date DATETIME NOT NULL,
terms_and_conditions VARCHAR(4000),
consent1_text VARCHAR(4000),
consent2_text VARCHAR(4000),
consent3_text VARCHAR(4000),
consent4_text VARCHAR(4000),
consent5_text VARCHAR(4000),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_crm_consent_info PRIMARY KEY CLUSTERED (organization_id, effective_date))
GO
EXEC CREATE_PROPERTY_TABLE crm_consent_info;
GO
PRINT '--- CREATING crm_customer_affiliation --- ';
CREATE TABLE dbo.crm_customer_affiliation(
organization_id INT NOT NULL,
party_id BIGINT NOT NULL,
cust_group_id VARCHAR(60) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_crm_customer_affiliation PRIMARY KEY CLUSTERED (organization_id, party_id, cust_group_id))
GO
EXEC CREATE_PROPERTY_TABLE crm_customer_affiliation;
GO
PRINT '--- CREATING crm_customer_notes --- ';
CREATE TABLE dbo.crm_customer_notes(
organization_id INT NOT NULL,
party_id BIGINT NOT NULL,
note_seq BIGINT NOT NULL,
note VARCHAR(MAX),
creator_id VARCHAR(254),
note_timestamp DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_crm_customer_notes PRIMARY KEY CLUSTERED (organization_id, party_id, note_seq))
GO
EXEC CREATE_PROPERTY_TABLE crm_customer_notes;
GO
PRINT '--- CREATING crm_customer_payment_card --- ';
CREATE TABLE dbo.crm_customer_payment_card(
organization_id INT NOT NULL,
party_id BIGINT NOT NULL,
card_token VARCHAR(254) NOT NULL,
card_alias VARCHAR(254),
card_type VARCHAR(60),
card_last_four VARCHAR(4),
expr_date VARCHAR(64),
shopper_ref VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_crm_customer_payment_card PRIMARY KEY CLUSTERED (organization_id, party_id, card_token))
GO
EXEC CREATE_PROPERTY_TABLE crm_customer_payment_card;
GO
PRINT '--- CREATING crm_gift_registry_journal --- ';
CREATE TABLE dbo.crm_gift_registry_journal(
organization_id INT NOT NULL,
journal_seq BIGINT NOT NULL,
registry_id BIGINT,
action_code VARCHAR(30),
registry_status VARCHAR(30),
trans_rtl_loc_id INT,
trans_wkstn_id BIGINT,
trans_business_date DATETIME,
trans_trans_seq BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_crm_gift_registry_journal PRIMARY KEY CLUSTERED (organization_id, journal_seq))
GO
PRINT '--- CREATING IDX_CRM_GFT_REGISTRY_JOURNAL01 --- ';
CREATE INDEX IDX_CRM_GFT_REGISTRY_JOURNAL01 ON dbo.crm_gift_registry_journal(registry_id)
GO

EXEC CREATE_PROPERTY_TABLE crm_gift_registry_journal;
GO
PRINT '--- CREATING crm_party --- ';
CREATE TABLE dbo.crm_party(
organization_id INT NOT NULL,
party_id BIGINT NOT NULL,
party_typcode VARCHAR(30),
cust_id VARCHAR(60),
employee_id VARCHAR(60),
salutation VARCHAR(30),
first_name VARCHAR(254),
middle_name VARCHAR(60),
last_name VARCHAR(254),
first_name2 VARCHAR(254),
last_name2 VARCHAR(254),
suffix VARCHAR(30),
gender VARCHAR(30),
preferred_locale VARCHAR(30),
birth_date DATETIME,
social_security_nbr VARCHAR(255),
national_tax_id VARCHAR(30),
personal_tax_id VARCHAR(30),
prospect_flag BIT DEFAULT (0),
rent_flag BIT DEFAULT (0),
privacy_card_flag BIT DEFAULT (0),
contact_pref VARCHAR(30),
sign_up_rtl_loc_id INT,
allegiance_rtl_loc_id INT,
anniversary_date DATETIME,
organization_typcode VARCHAR(30),
organization_name VARCHAR(254),
commercial_customer_flag BIT DEFAULT (0),
picture_uri VARCHAR(254),
void_flag BIT DEFAULT (0),
active_flag BIT DEFAULT (1) NOT NULL,
email_rcpts_flag BIT DEFAULT (0) NOT NULL,
save_card_payments_flag BIT DEFAULT (0) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_crm_party PRIMARY KEY CLUSTERED (organization_id, party_id))
GO
PRINT '--- CREATING XST_CRM_PARTY_CUSTID --- ';
CREATE INDEX XST_CRM_PARTY_CUSTID ON dbo.crm_party(cust_id, organization_id)
GO

PRINT '--- CREATING XST_CRM_PARTY_NAME_FIRST_LAST --- ';
CREATE INDEX XST_CRM_PARTY_NAME_FIRST_LAST ON dbo.crm_party(first_name, last_name)
GO

PRINT '--- CREATING XST_CRM_PARTY_NAME_LAST --- ';
CREATE INDEX XST_CRM_PARTY_NAME_LAST ON dbo.crm_party(last_name)
GO

PRINT '--- CREATING XST_CRM_PARTY_NAME_LAST_FIRST --- ';
CREATE INDEX XST_CRM_PARTY_NAME_LAST_FIRST ON dbo.crm_party(last_name, first_name)
GO

EXEC CREATE_PROPERTY_TABLE crm_party;
GO
PRINT '--- CREATING crm_party_cross_reference --- ';
CREATE TABLE dbo.crm_party_cross_reference(
organization_id INT NOT NULL,
parent_party_id BIGINT NOT NULL,
child_party_id BIGINT NOT NULL,
party_relationship_typcode VARCHAR(30) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_crm_party_cross_reference PRIMARY KEY CLUSTERED (organization_id, parent_party_id, child_party_id, party_relationship_typcode))
GO
PRINT '--- CREATING IDX_CRM_PARTY_XREF01 --- ';
CREATE INDEX IDX_CRM_PARTY_XREF01 ON dbo.crm_party_cross_reference(child_party_id)
GO

EXEC CREATE_PROPERTY_TABLE crm_party_cross_reference;
GO
PRINT '--- CREATING crm_party_email --- ';
CREATE TABLE dbo.crm_party_email(
organization_id INT NOT NULL,
party_id BIGINT NOT NULL,
email_sequence INT NOT NULL,
email_address VARCHAR(254),
email_type VARCHAR(20),
email_format VARCHAR(20),
contact_flag BIT DEFAULT (0),
primary_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_crm_party_email PRIMARY KEY CLUSTERED (organization_id, party_id, email_sequence))
GO
PRINT '--- CREATING XST_CRM_PARTY_EMAIL01 --- ';
CREATE INDEX XST_CRM_PARTY_EMAIL01 ON dbo.crm_party_email(email_address)
GO

EXEC CREATE_PROPERTY_TABLE crm_party_email;
GO
PRINT '--- CREATING crm_party_id_xref --- ';
CREATE TABLE dbo.crm_party_id_xref(
organization_id INT NOT NULL,
party_id BIGINT NOT NULL,
alternate_id_owner VARCHAR(30) NOT NULL,
alternate_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_crm_party_id_xref PRIMARY KEY CLUSTERED (organization_id, party_id, alternate_id_owner))
GO
PRINT '--- CREATING IDX_CRM_PARTY_ID_XREF01 --- ';
CREATE INDEX IDX_CRM_PARTY_ID_XREF01 ON dbo.crm_party_id_xref(alternate_id_owner, alternate_id)
GO

EXEC CREATE_PROPERTY_TABLE crm_party_id_xref;
GO
PRINT '--- CREATING crm_party_locale_information --- ';
CREATE TABLE dbo.crm_party_locale_information(
organization_id INT NOT NULL,
party_id BIGINT NOT NULL,
party_locale_seq INT NOT NULL,
address1 VARCHAR(254),
address2 VARCHAR(254),
address3 VARCHAR(254),
address4 VARCHAR(254),
apartment VARCHAR(30),
city VARCHAR(254),
state VARCHAR(30),
postal_code VARCHAR(30),
country VARCHAR(2),
neighborhood VARCHAR(254),
county VARCHAR(254),
contact_flag BIT DEFAULT (0),
primary_flag BIT DEFAULT (0),
address_type VARCHAR(20),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_crm_party_locale_information PRIMARY KEY CLUSTERED (organization_id, party_id, party_locale_seq))
GO
PRINT '--- CREATING XST_CRM_PARTYLOCALE_CITY --- ';
CREATE INDEX XST_CRM_PARTYLOCALE_CITY ON dbo.crm_party_locale_information(city)
GO

PRINT '--- CREATING XST_CRM_PARTYLOCALE_POSTAL --- ';
CREATE INDEX XST_CRM_PARTYLOCALE_POSTAL ON dbo.crm_party_locale_information(postal_code)
GO

PRINT '--- CREATING XST_CRM_PARTYLOCALE_STATE --- ';
CREATE INDEX XST_CRM_PARTYLOCALE_STATE ON dbo.crm_party_locale_information(state)
GO

EXEC CREATE_PROPERTY_TABLE crm_party_locale_information;
GO
PRINT '--- CREATING crm_party_telephone --- ';
CREATE TABLE dbo.crm_party_telephone(
organization_id INT NOT NULL,
party_id BIGINT NOT NULL,
telephone_type VARCHAR(20) NOT NULL,
telephone_number VARCHAR(32),
contact_type VARCHAR(20),
contact_flag BIT DEFAULT (0) NOT NULL,
primary_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_crm_party_telephone PRIMARY KEY CLUSTERED (organization_id, party_id, telephone_type))
GO
PRINT '--- CREATING XST_CRM_PARTY_TELEPHONE --- ';
CREATE INDEX XST_CRM_PARTY_TELEPHONE ON dbo.crm_party_telephone(telephone_number)
GO

EXEC CREATE_PROPERTY_TABLE crm_party_telephone;
GO
PRINT '--- CREATING crpt_daily_detail --- ';
CREATE TABLE dbo.crpt_daily_detail(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
business_date DATETIME NOT NULL,
trans_seq BIGINT NOT NULL,
ref_wkstn_id BIGINT NOT NULL,
record_type VARCHAR(30) NOT NULL,
sequence INT NOT NULL,
count01 BIGINT,
count02 BIGINT,
txt01 VARCHAR(2000),
txt02 VARCHAR(2000),
txt03 VARCHAR(2000),
txt04 VARCHAR(2000),
txt05 VARCHAR(2000),
txt06 VARCHAR(2000),
num01 DECIMAL(17, 6),
num02 DECIMAL(17, 6),
num03 DECIMAL(17, 6),
num04 DECIMAL(17, 6),
num05 DECIMAL(17, 6),
num06 DECIMAL(17, 6),
num07 DECIMAL(17, 6),
num08 DECIMAL(17, 6),
num09 DECIMAL(17, 6),
num10 DECIMAL(17, 6),
num11 DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_crpt_daily_detail PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq, ref_wkstn_id, record_type, sequence))
GO
EXEC CREATE_PROPERTY_TABLE crpt_daily_detail;
GO
PRINT '--- CREATING crpt_daily_header --- ';
CREATE TABLE dbo.crpt_daily_header(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
business_date DATETIME NOT NULL,
trans_seq BIGINT NOT NULL,
dailyreport_id BIGINT NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_crpt_daily_header PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq))
GO
EXEC CREATE_PROPERTY_TABLE crpt_daily_header;
GO
PRINT '--- CREATING ctl_app_version --- ';
CREATE TABLE dbo.ctl_app_version(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
seq INT NOT NULL,
app_id VARCHAR(255),
version_number VARCHAR(255),
version_priority VARCHAR(255),
effective_date DATETIME,
update_url VARCHAR(255),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_app_version PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, seq))
GO
PRINT '--- CREATING ctl_cheetah_device_access --- ';
CREATE TABLE dbo.ctl_cheetah_device_access(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
token VARCHAR(256) NOT NULL,
status VARCHAR(256) NOT NULL,
secret_hash VARCHAR(256),
secret_exp_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_cheetah_device_access PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, token))
GO
EXEC CREATE_PROPERTY_TABLE ctl_cheetah_device_access;
GO
PRINT '--- CREATING ctl_dataloader_failure --- ';
CREATE TABLE dbo.ctl_dataloader_failure(
organization_id INT NOT NULL,
file_name VARCHAR(254) NOT NULL,
run_timestamp BIGINT NOT NULL,
failure_seq INT NOT NULL,
failure_message VARCHAR(4000) NOT NULL,
failed_data VARCHAR(4000),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_dataloader_failure PRIMARY KEY CLUSTERED (organization_id, file_name, run_timestamp, failure_seq))
GO
PRINT '--- CREATING ctl_dataloader_summary --- ';
CREATE TABLE dbo.ctl_dataloader_summary(
organization_id INT NOT NULL,
file_name VARCHAR(254) NOT NULL,
run_timestamp BIGINT NOT NULL,
success_flag BIT DEFAULT (0) NOT NULL,
successful_rows INT,
failed_rows INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_dataloader_summary PRIMARY KEY CLUSTERED (organization_id, file_name, run_timestamp))
GO
PRINT '--- CREATING ctl_device_config --- ';
CREATE TABLE dbo.ctl_device_config(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
hardware_family_type VARCHAR(100) NOT NULL,
hardware_use VARCHAR(100) NOT NULL,
description VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_device_config PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, hardware_family_type, hardware_use))
GO
EXEC CREATE_PROPERTY_TABLE ctl_device_config;
GO
PRINT '--- CREATING ctl_device_fiscal_info --- ';
CREATE TABLE dbo.ctl_device_fiscal_info(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
hardware_family_type VARCHAR(100) NOT NULL,
hardware_use VARCHAR(100) NOT NULL,
device_id VARCHAR(100),
status VARCHAR(255),
fiscal_session_number VARCHAR(100),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_device_fiscal_info PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, hardware_family_type, hardware_use))
GO
EXEC CREATE_PROPERTY_TABLE ctl_device_fiscal_info;
GO
PRINT '--- CREATING ctl_device_information --- ';
CREATE TABLE dbo.ctl_device_information(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
dev_seq INT NOT NULL,
device_name VARCHAR(255),
device_type VARCHAR(255),
model VARCHAR(255),
serial_number VARCHAR(255),
firmware VARCHAR(255),
firmware_date DATETIME,
asset_status VARCHAR(255),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_device_information PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, dev_seq))
GO
PRINT '--- CREATING ctl_device_registration --- ';
CREATE TABLE dbo.ctl_device_registration(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
ip_address VARCHAR(30),
date_timestamp DATETIME,
business_date DATETIME,
xstore_version VARCHAR(40),
env_version VARCHAR(40),
active_flag BIT DEFAULT (0) NOT NULL,
config_version VARCHAR(40),
machine_name VARCHAR(255),
mac_address VARCHAR(20),
primary_register_flag BIT DEFAULT (0) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_device_registration PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id))
GO
EXEC CREATE_PROPERTY_TABLE ctl_device_registration;
GO
PRINT '--- CREATING ctl_event_log --- ';
CREATE TABLE dbo.ctl_event_log(
organization_id INT,
rtl_loc_id INT,
wkstn_id BIGINT,
business_date DATETIME,
operator_party_id BIGINT,
log_level VARCHAR(20),
log_timestamp DATETIME NOT NULL,
source VARCHAR(254),
thread_name VARCHAR(254),
critical_to_deliver BIT DEFAULT (0),
logger_category VARCHAR(254),
log_message VARCHAR(MAX) NOT NULL,
arrival_timestamp DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30))
GO
PRINT '--- CREATING IDX_CTL_EVENT_LOG01 --- ';
CREATE INDEX IDX_CTL_EVENT_LOG01 ON dbo.ctl_event_log(log_timestamp)
GO

PRINT '--- CREATING IDX_CTL_EVENT_LOG_CREATE_DATE --- ';
CREATE INDEX IDX_CTL_EVENT_LOG_CREATE_DATE ON dbo.ctl_event_log(create_date)
GO

PRINT '--- CREATING IDX_CTL_EVENT_LOG02 --- ';
CREATE INDEX IDX_CTL_EVENT_LOG02 ON dbo.ctl_event_log(arrival_timestamp, organization_id, logger_category, create_date)
GO

PRINT '--- CREATING ctl_ip_cashdrawer_device --- ';
CREATE TABLE dbo.ctl_ip_cashdrawer_device(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
cash_drawer_id VARCHAR(60) NOT NULL,
drawer_status VARCHAR(40),
product_name VARCHAR(80),
description VARCHAR(80),
serial_number VARCHAR(40),
ip_address VARCHAR(16),
tcp_port INT,
mac_address VARCHAR(20),
subnet_mask VARCHAR(16),
gateway VARCHAR(16),
dns_hostname VARCHAR(16),
dhcp_flag BIT DEFAULT (0),
firmware_version VARCHAR(20),
kup VARCHAR(1024),
kup_update_date DATETIME,
beep_on_open_flag BIT DEFAULT (0),
beep_long_open_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_ip_cashdrawer_device PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, cash_drawer_id))
GO
EXEC CREATE_PROPERTY_TABLE ctl_ip_cashdrawer_device;
GO
PRINT '--- CREATING ctl_log_trickle --- ';
CREATE TABLE dbo.ctl_log_trickle(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
log_trickle_id VARCHAR(60) NOT NULL,
log_type VARCHAR(60),
log_data VARCHAR(MAX),
posted_flag BIT DEFAULT (0),
log_generated_datetime DATETIME,
log_posted_datetime DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_log_trickle PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, log_trickle_id))
GO
PRINT '--- CREATING ctl_mobile_server --- ';
CREATE TABLE dbo.ctl_mobile_server(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
hostname VARCHAR(254) NOT NULL,
port BIGINT NOT NULL,
alias VARCHAR(254) NOT NULL,
wkstn_range_start INT,
wkstn_range_end INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_mobile_server PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, hostname, port))
GO
EXEC CREATE_PROPERTY_TABLE ctl_mobile_server;
GO
PRINT '--- CREATING ctl_offline_pos_transaction --- ';
CREATE TABLE dbo.ctl_offline_pos_transaction(
organization_id INT NOT NULL,
uuid VARCHAR(36) NOT NULL,
rtl_loc_id INT,
wkstn_id BIGINT,
timestamp_end DATETIME,
cust_email VARCHAR(254),
sale_items_count INT,
trans_total DECIMAL(17, 6),
serialized_data VARBINARY(MAX) NOT NULL,
processed_flag BIT DEFAULT (0) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_offline_pos_transaction PRIMARY KEY CLUSTERED (organization_id, uuid))
GO
EXEC CREATE_PROPERTY_TABLE ctl_offline_pos_transaction;
GO
PRINT '--- CREATING ctl_service_response_log --- ';
CREATE TABLE dbo.ctl_service_response_log(
organization_id INT NOT NULL,
system_id VARCHAR(25) NOT NULL,
message_id VARCHAR(255) NOT NULL,
message_count INT,
reference_id VARCHAR(255),
error VARCHAR(MAX),
detail VARCHAR(MAX),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_service_response_log PRIMARY KEY CLUSTERED (organization_id, system_id, message_id))
GO
PRINT '--- CREATING ctl_version_history --- ';
CREATE TABLE dbo.ctl_version_history(
organization_id INT NOT NULL,
seq BIGINT IDENTITY(1,1),
base_schema_version VARCHAR(30) NOT NULL,
customer_schema_version VARCHAR(30) NOT NULL,
customer VARCHAR(30),
base_schema_date DATETIME,
customer_schema_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ctl_version_history PRIMARY KEY CLUSTERED (organization_id, seq))
GO
EXEC CREATE_PROPERTY_TABLE ctl_version_history;
GO
PRINT '--- CREATING cwo_category_service_loc --- ';
CREATE TABLE dbo.cwo_category_service_loc(
organization_id INT NOT NULL,
category_id VARCHAR(60) NOT NULL,
service_loc_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
lead_time_qty DECIMAL(11, 4),
lead_time_unit_enum VARCHAR(30),
create_shipment_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cwo_category_service_loc PRIMARY KEY CLUSTERED (organization_id, category_id, service_loc_id))
GO
PRINT '--- CREATING IDX_CWO_CAT_SERVCE_LOC_ORGNODE --- ';
CREATE INDEX IDX_CWO_CAT_SERVCE_LOC_ORGNODE ON dbo.cwo_category_service_loc(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE cwo_category_service_loc;
GO
PRINT '--- CREATING cwo_invoice --- ';
CREATE TABLE dbo.cwo_invoice(
organization_id INT NOT NULL,
service_loc_id VARCHAR(60) NOT NULL,
invoice_number VARCHAR(60) NOT NULL,
invoice_date DATETIME,
amount_due DECIMAL(17, 6),
notes VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cwo_invoice PRIMARY KEY CLUSTERED (organization_id, service_loc_id, invoice_number))
GO
EXEC CREATE_PROPERTY_TABLE cwo_invoice;
GO
PRINT '--- CREATING cwo_invoice_gl --- ';
CREATE TABLE dbo.cwo_invoice_gl(
organization_id INT NOT NULL,
gl_account_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
description VARCHAR(254),
no_cost_with_warranty_flag BIT DEFAULT (0),
no_cost_without_warranty_flag BIT DEFAULT (0),
sort_order INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cwo_invoice_gl PRIMARY KEY CLUSTERED (organization_id, gl_account_id))
GO
PRINT '--- CREATING IDX_CWO_INVOICE_GL_ORGNODE --- ';
CREATE INDEX IDX_CWO_INVOICE_GL_ORGNODE ON dbo.cwo_invoice_gl(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE cwo_invoice_gl;
GO
PRINT '--- CREATING cwo_invoice_lineitm --- ';
CREATE TABLE dbo.cwo_invoice_lineitm(
organization_id INT NOT NULL,
service_loc_id VARCHAR(60) NOT NULL,
invoice_number VARCHAR(60) NOT NULL,
invoice_lineitm_seq INT NOT NULL,
lineitm_typcode VARCHAR(30),
amt DECIMAL(17, 6),
gl_account VARCHAR(60),
cust_acct_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cwo_invoice_lineitm PRIMARY KEY CLUSTERED (organization_id, service_loc_id, invoice_number, invoice_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE cwo_invoice_lineitm;
GO
PRINT '--- CREATING cwo_price_code --- ';
CREATE TABLE dbo.cwo_price_code(
organization_id INT NOT NULL,
price_code VARCHAR(30) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
description VARCHAR(254),
sort_order INT,
prompt_for_warranty_nbr_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cwo_price_code PRIMARY KEY CLUSTERED (organization_id, price_code))
GO
PRINT '--- CREATING IDX_CWO_PRICE_CODE_ORGNODE --- ';
CREATE INDEX IDX_CWO_PRICE_CODE_ORGNODE ON dbo.cwo_price_code(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE cwo_price_code;
GO
PRINT '--- CREATING cwo_service_loc --- ';
CREATE TABLE dbo.cwo_service_loc(
organization_id INT NOT NULL,
service_loc_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
description VARCHAR(254),
party_id BIGINT,
address_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cwo_service_loc PRIMARY KEY CLUSTERED (organization_id, service_loc_id))
GO
PRINT '--- CREATING IDX_CWO_SERVICE_LOC_ORGNODE --- ';
CREATE INDEX IDX_CWO_SERVICE_LOC_ORGNODE ON dbo.cwo_service_loc(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE cwo_service_loc;
GO
PRINT '--- CREATING cwo_task --- ';
CREATE TABLE dbo.cwo_task(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
category_id VARCHAR(60),
price_type_enum VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cwo_task PRIMARY KEY CLUSTERED (organization_id, item_id))
GO
PRINT '--- CREATING cwo_work_item --- ';
CREATE TABLE dbo.cwo_work_item(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
work_item_seq INT NOT NULL,
item_id VARCHAR(60),
description VARCHAR(254),
value_amt DECIMAL(17, 6),
warranty_number VARCHAR(254),
work_item_serial_nbr VARCHAR(254),
void_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cwo_work_item PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id, work_item_seq))
GO
EXEC CREATE_PROPERTY_TABLE cwo_work_item;
GO
PRINT '--- CREATING cwo_work_order_acct --- ';
CREATE TABLE dbo.cwo_work_order_acct(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
service_loc_id VARCHAR(60) NOT NULL,
category_id VARCHAR(60) NOT NULL,
total_value DECIMAL(17, 6),
estimated_completion_date DATETIME,
approved_work_amt DECIMAL(17, 6),
approved_work_date DATETIME,
priority_code VARCHAR(30),
price_code VARCHAR(30),
contact_method_code VARCHAR(30),
last_cust_notice DATETIME,
cost DECIMAL(17, 6),
invoice_number VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cwo_work_order_acct PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id))
GO
PRINT '--- CREATING cwo_work_order_acct_journal --- ';
CREATE TABLE dbo.cwo_work_order_acct_journal(
organization_id INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
journal_seq BIGINT NOT NULL,
total_value DECIMAL(17, 6),
estimated_completion_date DATETIME,
approved_work_amt DECIMAL(17, 6),
approved_work_date DATETIME,
priority_code VARCHAR(30),
price_code VARCHAR(30),
category_id VARCHAR(60),
contact_method VARCHAR(30),
last_cust_notice DATETIME,
service_loc_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cwo_work_order_acct_journal PRIMARY KEY CLUSTERED (organization_id, cust_acct_code, cust_acct_id, journal_seq))
GO
PRINT '--- CREATING cwo_work_order_category --- ';
CREATE TABLE dbo.cwo_work_order_category(
organization_id INT NOT NULL,
category_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
sort_order INT,
description VARCHAR(254),
prompt_for_price_code_flag BIT DEFAULT (0),
max_item_count DECIMAL(11, 4),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cwo_work_order_category PRIMARY KEY CLUSTERED (organization_id, category_id))
GO
PRINT '--- CREATING IDX_CWO_WORK_ORDER_CAT_ORGNODE --- ';
CREATE INDEX IDX_CWO_WORK_ORDER_CAT_ORGNODE ON dbo.cwo_work_order_category(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE cwo_work_order_category;
GO
PRINT '--- CREATING cwo_work_order_line_item --- ';
CREATE TABLE dbo.cwo_work_order_line_item(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
price_status_enum VARCHAR(30),
instructions VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cwo_work_order_line_item PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING cwo_work_order_pricing --- ';
CREATE TABLE dbo.cwo_work_order_pricing(
organization_id INT NOT NULL,
price_code VARCHAR(30) NOT NULL,
item_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
price DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_cwo_work_order_pricing PRIMARY KEY CLUSTERED (organization_id, price_code, item_id))
GO
PRINT '--- CREATING IDX_CWOWORKORDERPRICINGORGNODE --- ';
CREATE INDEX IDX_CWOWORKORDERPRICINGORGNODE ON dbo.cwo_work_order_pricing(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE cwo_work_order_pricing;
GO
PRINT '--- CREATING doc_document --- ';
CREATE TABLE dbo.doc_document(
organization_id INT NOT NULL,
document_type VARCHAR(30) NOT NULL,
series_id VARCHAR(60) NOT NULL,
document_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
document_status VARCHAR(30),
issue_date DATETIME,
effective_date DATETIME,
expiration_date DATETIME,
amount DECIMAL(17, 6),
percentage DECIMAL(17, 6),
max_amount DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_doc_document PRIMARY KEY CLUSTERED (organization_id, document_type, series_id, document_id))
GO
PRINT '--- CREATING IDX_DOC_DOCUMENT_ORGNODE --- ';
CREATE INDEX IDX_DOC_DOCUMENT_ORGNODE ON dbo.doc_document(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE doc_document;
GO
PRINT '--- CREATING doc_document_def_properties --- ';
CREATE TABLE dbo.doc_document_def_properties(
organization_id INT NOT NULL,
document_type VARCHAR(30) NOT NULL,
series_id VARCHAR(60) NOT NULL,
doc_seq_nbr INT NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
property_code VARCHAR(30),
type VARCHAR(30),
string_value VARCHAR(254),
date_value DATETIME,
decimal_value DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_doc_document_def_properties PRIMARY KEY CLUSTERED (organization_id, document_type, series_id, doc_seq_nbr))
GO
PRINT '--- CREATING IDX_DOCDOCUMENTDEFPROPORGNODE --- ';
CREATE INDEX IDX_DOCDOCUMENTDEFPROPORGNODE ON dbo.doc_document_def_properties(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE doc_document_def_properties;
GO
PRINT '--- CREATING doc_document_definition --- ';
CREATE TABLE dbo.doc_document_definition(
organization_id INT NOT NULL,
series_id VARCHAR(60) NOT NULL,
document_type VARCHAR(30) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
start_issue_date DATETIME,
end_issue_date DATETIME,
start_redeem_date DATETIME,
end_redeem_date DATETIME,
receipt_type VARCHAR(30),
segment_type VARCHAR(30),
text_code_value VARCHAR(30),
file_name VARCHAR(254),
vendor_id VARCHAR(60),
description VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_doc_document_definition PRIMARY KEY CLUSTERED (organization_id, series_id, document_type))
GO
PRINT '--- CREATING IDX_DOC_DOCUMENT_DEF_ORGNODE --- ';
CREATE INDEX IDX_DOC_DOCUMENT_DEF_ORGNODE ON dbo.doc_document_definition(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE doc_document_definition;
GO
PRINT '--- CREATING doc_document_lineitm --- ';
CREATE TABLE dbo.doc_document_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
document_id VARCHAR(60),
document_type VARCHAR(30),
series_id VARCHAR(60),
activity_code VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_doc_document_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING dsc_coupon_xref --- ';
CREATE TABLE dbo.dsc_coupon_xref(
organization_id INT NOT NULL,
coupon_serial_nbr VARCHAR(254) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
discount_code VARCHAR(60),
tndr_id VARCHAR(60),
coupon_type VARCHAR(60),
serialized_flag BIT DEFAULT (0),
effective_date DATETIME,
expiration_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_dsc_coupon_xref PRIMARY KEY CLUSTERED (organization_id, coupon_serial_nbr))
GO
PRINT '--- CREATING IDX_DSC_COUPON_XREF_ORGNODE --- ';
CREATE INDEX IDX_DSC_COUPON_XREF_ORGNODE ON dbo.dsc_coupon_xref(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE dsc_coupon_xref;
GO
PRINT '--- CREATING dsc_disc_type_eligibility --- ';
CREATE TABLE dbo.dsc_disc_type_eligibility(
organization_id INT NOT NULL,
discount_code VARCHAR(60) NOT NULL,
sale_lineitm_typcode VARCHAR(30) NOT NULL,
config_element VARCHAR(200) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_dsc_disc_type_eligibility PRIMARY KEY CLUSTERED (organization_id, discount_code, sale_lineitm_typcode))
GO
EXEC CREATE_PROPERTY_TABLE dsc_disc_type_eligibility;
GO
PRINT '--- CREATING dsc_discount --- ';
CREATE TABLE dbo.dsc_discount(
organization_id INT NOT NULL,
discount_code VARCHAR(60) NOT NULL,
effective_datetime DATETIME NOT NULL,
expr_datetime DATETIME,
typcode VARCHAR(30),
app_mthd_code VARCHAR(30) NOT NULL,
percentage DECIMAL(6, 4),
description VARCHAR(254),
calculation_mthd_code VARCHAR(30) NOT NULL,
prompt VARCHAR(254),
sound VARCHAR(254),
max_trans_count INT,
exclusive_discount_flag BIT DEFAULT (0),
privilege_type VARCHAR(60),
discount DECIMAL(17, 6),
dtv_class_name VARCHAR(254),
min_eligible_price DECIMAL(17, 6),
serialized_discount_flag BIT DEFAULT (0),
taxability_code VARCHAR(30),
max_discount DECIMAL(17, 6),
sort_order INT,
disallow_change_flag BIT DEFAULT (0),
max_amount DECIMAL(17, 6),
max_percentage DECIMAL(17, 6),
config_element VARCHAR(200) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_dsc_discount PRIMARY KEY CLUSTERED (organization_id, discount_code))
GO
EXEC CREATE_PROPERTY_TABLE dsc_discount;
GO
PRINT '--- CREATING dsc_discount_compatibility --- ';
CREATE TABLE dbo.dsc_discount_compatibility(
organization_id INT NOT NULL,
primary_discount_code VARCHAR(60) NOT NULL,
compatible_discount_code VARCHAR(60) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_dsc_discount_compatibility PRIMARY KEY CLUSTERED (organization_id, primary_discount_code, compatible_discount_code))
GO
EXEC CREATE_PROPERTY_TABLE dsc_discount_compatibility;
GO
PRINT '--- CREATING dsc_discount_group_mapping --- ';
CREATE TABLE dbo.dsc_discount_group_mapping(
organization_id INT NOT NULL,
cust_group_id VARCHAR(60) NOT NULL,
discount_code VARCHAR(60) NOT NULL,
config_element VARCHAR(200) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_dsc_discount_group_mapping PRIMARY KEY CLUSTERED (organization_id, cust_group_id, discount_code))
GO
EXEC CREATE_PROPERTY_TABLE dsc_discount_group_mapping;
GO
PRINT '--- CREATING dsc_discount_item_exclusions --- ';
CREATE TABLE dbo.dsc_discount_item_exclusions(
organization_id INT NOT NULL,
discount_code VARCHAR(60) NOT NULL,
item_id VARCHAR(60) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_dsc_discount_item_exclusions PRIMARY KEY CLUSTERED (organization_id, discount_code, item_id))
GO
EXEC CREATE_PROPERTY_TABLE dsc_discount_item_exclusions;
GO
PRINT '--- CREATING dsc_discount_item_inclusions --- ';
CREATE TABLE dbo.dsc_discount_item_inclusions(
organization_id INT NOT NULL,
discount_code VARCHAR(60) NOT NULL,
item_id VARCHAR(60) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_dsc_discount_item_inclusions PRIMARY KEY CLUSTERED (organization_id, discount_code, item_id))
GO
EXEC CREATE_PROPERTY_TABLE dsc_discount_item_inclusions;
GO
PRINT '--- CREATING egt_room --- ';
CREATE TABLE dbo.egt_room(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
room_lineitm_seq INT NOT NULL,
room_id VARCHAR(254),
assign_datetime DATETIME,
release_datetime DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_egt_room PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, room_lineitm_seq))
GO
PRINT '--- CREATING egt_trans --- ';
CREATE TABLE dbo.egt_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
cust_party_id BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_egt_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING egt_trans_lineitm --- ';
CREATE TABLE dbo.egt_trans_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
item_id_entry_mthd_code VARCHAR(30),
item_id VARCHAR(60),
unit_price DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_egt_trans_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE egt_trans_lineitm;
GO
PRINT '--- CREATING hrs_employee --- ';
CREATE TABLE dbo.hrs_employee(
organization_id INT NOT NULL,
employee_id VARCHAR(60) NOT NULL,
party_id BIGINT,
login_id VARCHAR(60),
sick_days_used DECIMAL(11, 2),
hire_date DATETIME,
active_date DATETIME,
terminated_date DATETIME,
job_title VARCHAR(254),
base_pay DECIMAL(17, 6),
add_date DATETIME,
marital_status VARCHAR(30),
spouse_name VARCHAR(254),
emergency_contact_name VARCHAR(254),
emergency_contact_phone VARCHAR(32),
last_review_date DATETIME,
next_review_date DATETIME,
additional_withholdings DECIMAL(17, 6),
vacation_days DECIMAL(11, 2),
vacation_days_used DECIMAL(11, 2),
sick_days DECIMAL(11, 2),
personal_days DECIMAL(11, 2),
personal_days_used DECIMAL(11, 2),
clock_in_not_req_flag BIT DEFAULT (0),
employee_pay_status VARCHAR(30),
employee_role_code VARCHAR(30),
employee_statcode VARCHAR(30),
clocked_in_flag BIT DEFAULT (0),
work_code VARCHAR(30),
group_membership VARCHAR(MAX),
primary_group VARCHAR(60),
department_id VARCHAR(60),
employee_typcode VARCHAR(30),
training_status_enum VARCHAR(30),
locked_out_flag BIT DEFAULT (0),
locked_out_timestamp DATETIME,
overtime_eligible_flag BIT DEFAULT (0),
employee_group_id VARCHAR(60),
employee_work_status VARCHAR(30),
keyed_offline_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_hrs_employee PRIMARY KEY CLUSTERED (organization_id, employee_id))
GO
PRINT '--- CREATING XST_HRS_EMPLOYEE_PARTYID --- ';
CREATE INDEX XST_HRS_EMPLOYEE_PARTYID ON dbo.hrs_employee(party_id, organization_id)
GO

EXEC CREATE_PROPERTY_TABLE hrs_employee;
GO
PRINT '--- CREATING hrs_employee_answers --- ';
CREATE TABLE dbo.hrs_employee_answers(
organization_id INT NOT NULL,
employee_id VARCHAR(60) NOT NULL,
challenge_code VARCHAR(60) NOT NULL,
challenge_answer VARCHAR(4000),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_hrs_employee_answers PRIMARY KEY CLUSTERED (organization_id, employee_id, challenge_code))
GO
EXEC CREATE_PROPERTY_TABLE hrs_employee_answers;
GO
PRINT '--- CREATING hrs_employee_fingerprint --- ';
CREATE TABLE dbo.hrs_employee_fingerprint(
organization_id INT NOT NULL,
employee_id VARCHAR(60) NOT NULL,
fingerprint_seq INT NOT NULL,
fingerprint_storage VARCHAR(MAX),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_hrs_employee_fingerprint PRIMARY KEY CLUSTERED (organization_id, employee_id, fingerprint_seq))
GO
EXEC CREATE_PROPERTY_TABLE hrs_employee_fingerprint;
GO
PRINT '--- CREATING hrs_employee_message --- ';
CREATE TABLE dbo.hrs_employee_message(
organization_id INT NOT NULL,
message_id BIGINT NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
start_date DATETIME,
end_date DATETIME,
priority VARCHAR(20),
content VARCHAR(MAX),
store_created_flag BIT DEFAULT (0),
wkstn_specific_flag BIT DEFAULT (0),
wkstn_id BIGINT,
void_flag BIT DEFAULT (0),
message_url VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_hrs_employee_message PRIMARY KEY CLUSTERED (organization_id, message_id))
GO
PRINT '--- CREATING IDX_HRS_EMPLOYEE_MSG_ORGNODE --- ';
CREATE INDEX IDX_HRS_EMPLOYEE_MSG_ORGNODE ON dbo.hrs_employee_message(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE hrs_employee_message;
GO
PRINT '--- CREATING hrs_employee_notes --- ';
CREATE TABLE dbo.hrs_employee_notes(
organization_id INT NOT NULL,
employee_id VARCHAR(60) NOT NULL,
note_seq BIGINT NOT NULL,
note VARCHAR(MAX),
creator_party_id BIGINT,
note_timestamp DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_hrs_employee_notes PRIMARY KEY CLUSTERED (organization_id, employee_id, note_seq))
GO
EXEC CREATE_PROPERTY_TABLE hrs_employee_notes;
GO
PRINT '--- CREATING hrs_employee_password --- ';
CREATE TABLE dbo.hrs_employee_password(
organization_id INT NOT NULL,
employee_id VARCHAR(60) NOT NULL,
password_seq BIGINT DEFAULT (0) NOT NULL,
password VARCHAR(254),
effective_date DATETIME NOT NULL,
temp_password_flag BIT DEFAULT (0) NOT NULL,
current_password_flag BIT DEFAULT (1) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_hrs_employee_password PRIMARY KEY CLUSTERED (organization_id, employee_id, password_seq))
GO
EXEC CREATE_PROPERTY_TABLE hrs_employee_password;
GO
PRINT '--- CREATING hrs_employee_store --- ';
CREATE TABLE dbo.hrs_employee_store(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
employee_id VARCHAR(60) NOT NULL,
employee_store_seq INT NOT NULL,
begin_date DATETIME,
end_date DATETIME,
temp_assignment_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_hrs_employee_store PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, employee_id, employee_store_seq))
GO
EXEC CREATE_PROPERTY_TABLE hrs_employee_store;
GO
PRINT '--- CREATING hrs_employee_task --- ';
CREATE TABLE dbo.hrs_employee_task(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
task_id BIGINT NOT NULL,
start_date DATETIME,
end_date DATETIME,
complete_date DATETIME,
typcode VARCHAR(60),
visibility VARCHAR(30),
assignment_id VARCHAR(60),
store_created_flag BIT DEFAULT (0),
title VARCHAR(255),
description VARCHAR(MAX),
priority VARCHAR(20),
status_code VARCHAR(30),
void_flag BIT DEFAULT (0),
party_id BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_hrs_employee_task PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, task_id))
GO
EXEC CREATE_PROPERTY_TABLE hrs_employee_task;
GO
PRINT '--- CREATING hrs_employee_task_notes --- ';
CREATE TABLE dbo.hrs_employee_task_notes(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
task_id BIGINT NOT NULL,
note_seq BIGINT NOT NULL,
note VARCHAR(MAX),
creator_party_id BIGINT,
note_timestamp DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_hrs_employee_task_notes PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, task_id, note_seq))
GO
EXEC CREATE_PROPERTY_TABLE hrs_employee_task_notes;
GO
PRINT '--- CREATING hrs_work_codes --- ';
CREATE TABLE dbo.hrs_work_codes(
organization_id INT NOT NULL,
work_code VARCHAR(30) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
description VARCHAR(254),
sort_order INT,
privilege VARCHAR(60),
selling_flag BIT DEFAULT (0),
payroll_category VARCHAR(30),
min_clock_in_duration INT,
min_clock_out_duration INT,
hidden_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_hrs_work_codes PRIMARY KEY CLUSTERED (organization_id, work_code))
GO
PRINT '--- CREATING IDX_HRS_WORK_CODES_ORGNODE --- ';
CREATE INDEX IDX_HRS_WORK_CODES_ORGNODE ON dbo.hrs_work_codes(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE hrs_work_codes;
GO
PRINT '--- CREATING inv_bucket --- ';
CREATE TABLE dbo.inv_bucket(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
bucket_id VARCHAR(60) NOT NULL,
name VARCHAR(254),
function_code VARCHAR(30),
adjustment_action VARCHAR(30),
default_location_id VARCHAR(60),
system_bucket_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_bucket PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, bucket_id))
GO
EXEC CREATE_PROPERTY_TABLE inv_bucket;
GO
PRINT '--- CREATING inv_carton --- ';
CREATE TABLE dbo.inv_carton(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
invctl_document_id VARCHAR(60) NOT NULL,
carton_id VARCHAR(60) NOT NULL,
carton_statcode VARCHAR(30),
record_creation_type VARCHAR(30),
control_number VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_carton PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, document_typcode, invctl_document_id, carton_id))
GO
EXEC CREATE_PROPERTY_TABLE inv_carton;
GO
PRINT '--- CREATING inv_count --- ';
CREATE TABLE dbo.inv_count(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
inv_count_id VARCHAR(60) NOT NULL,
inv_location_id VARCHAR(60),
inv_count_typcode VARCHAR(60) NOT NULL,
begin_date DATETIME,
end_date DATETIME,
count_status VARCHAR(60),
store_created_flag BIT DEFAULT (0) NOT NULL,
void_flag BIT DEFAULT (0) NOT NULL,
description VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_count PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, inv_count_id))
GO
EXEC CREATE_PROPERTY_TABLE inv_count;
GO
PRINT '--- CREATING inv_count_bucket --- ';
CREATE TABLE dbo.inv_count_bucket(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
inv_count_id VARCHAR(60) NOT NULL,
inv_bucket_id VARCHAR(60) NOT NULL,
count_cycle INT,
bucket_status VARCHAR(60),
inv_bucket_name VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_count_bucket PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, inv_count_id, inv_bucket_id))
GO
EXEC CREATE_PROPERTY_TABLE inv_count_bucket;
GO
PRINT '--- CREATING inv_count_mismatch --- ';
CREATE TABLE dbo.inv_count_mismatch(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
inv_count_id VARCHAR(60) NOT NULL,
count_sheet_nbr INT NOT NULL,
inv_location_id VARCHAR(60) NOT NULL,
inv_bucket_id VARCHAR(60) NOT NULL,
item_id VARCHAR(60) NOT NULL,
snapshot_date DATETIME,
stock_qty DECIMAL(14, 4),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_count_mismatch PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, inv_count_id, count_sheet_nbr, inv_location_id, inv_bucket_id, item_id))
GO
PRINT '--- CREATING inv_count_section --- ';
CREATE TABLE dbo.inv_count_section(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
inv_location_id VARCHAR(60) NOT NULL,
inv_bucket_id VARCHAR(60) NOT NULL,
section_id VARCHAR(60) NOT NULL,
sort_order INT,
inv_bucket_name VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_count_section PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, inv_location_id, inv_bucket_id, section_id))
GO
EXEC CREATE_PROPERTY_TABLE inv_count_section;
GO
PRINT '--- CREATING inv_count_section_detail --- ';
CREATE TABLE dbo.inv_count_section_detail(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
inv_location_id VARCHAR(60) NOT NULL,
inv_bucket_id VARCHAR(60) NOT NULL,
section_id VARCHAR(60) NOT NULL,
section_detail_nbr INT NOT NULL,
merch_hierarchy_level VARCHAR(60),
merch_hierarchy_id VARCHAR(60),
description VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_count_section_detail PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, inv_location_id, inv_bucket_id, section_id, section_detail_nbr))
GO
EXEC CREATE_PROPERTY_TABLE inv_count_section_detail;
GO
PRINT '--- CREATING inv_count_sheet --- ';
CREATE TABLE dbo.inv_count_sheet(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
inv_count_id VARCHAR(60) NOT NULL,
count_sheet_nbr INT NOT NULL,
inv_bucket_id VARCHAR(60),
section_nbr INT,
section_id VARCHAR(60),
count_cycle INT,
sheet_status VARCHAR(60),
checked_out_flag BIT DEFAULT (0) NOT NULL,
inv_bucket_name VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_count_sheet PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, inv_count_id, count_sheet_nbr))
GO
EXEC CREATE_PROPERTY_TABLE inv_count_sheet;
GO
PRINT '--- CREATING inv_count_sheet_lineitm --- ';
CREATE TABLE dbo.inv_count_sheet_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
inv_count_id VARCHAR(60) NOT NULL,
count_sheet_nbr INT NOT NULL,
lineitm_nbr INT NOT NULL,
inv_bucket_id VARCHAR(60),
page_nbr INT,
item_id VARCHAR(60),
alternate_id VARCHAR(60),
description VARCHAR(200),
quantity DECIMAL(14, 4),
count_cycle INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_count_sheet_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, inv_count_id, count_sheet_nbr, lineitm_nbr))
GO
PRINT '--- CREATING IDX_INV_COUNT_SHEET_LINEITM01 --- ';
CREATE INDEX IDX_INV_COUNT_SHEET_LINEITM01 ON dbo.inv_count_sheet_lineitm(inv_count_id, inv_bucket_id, item_id, alternate_id, description)
GO

EXEC CREATE_PROPERTY_TABLE inv_count_sheet_lineitm;
GO
PRINT '--- CREATING inv_count_snapshot --- ';
CREATE TABLE dbo.inv_count_snapshot(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
inv_count_id VARCHAR(60) NOT NULL,
inv_location_id VARCHAR(60) NOT NULL,
inv_bucket_id VARCHAR(60) NOT NULL,
item_id VARCHAR(60) NOT NULL,
snapshot_date DATETIME,
quantity DECIMAL(14, 4),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_count_snapshot PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, inv_count_id, inv_location_id, inv_bucket_id, item_id))
GO
EXEC CREATE_PROPERTY_TABLE inv_count_snapshot;
GO
PRINT '--- CREATING inv_cst_item_yearend --- ';
CREATE TABLE dbo.inv_cst_item_yearend(
organization_id INT NOT NULL,
fiscal_year INT NOT NULL,
rtl_loc_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
wac_qty_rcvd DECIMAL(14, 4),
wac_value_rcvd DECIMAL(17, 6),
pwac_qty_onhand_endofyear DECIMAL(14, 4),
pwac_value_onhand_endofyear DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_cst_item_yearend PRIMARY KEY CLUSTERED (organization_id, fiscal_year, rtl_loc_id, item_id))
GO
PRINT '--- CREATING IDX_INV_CST_ITEM_YEAREND_01 --- ';
CREATE INDEX IDX_INV_CST_ITEM_YEAREND_01 ON dbo.inv_cst_item_yearend(fiscal_year)
GO

PRINT '--- CREATING IDX_INV_CST_ITEM_YEAREND_02 --- ';
CREATE INDEX IDX_INV_CST_ITEM_YEAREND_02 ON dbo.inv_cst_item_yearend(rtl_loc_id)
GO

EXEC CREATE_PROPERTY_TABLE inv_cst_item_yearend;
GO
PRINT '--- CREATING inv_document_lineitm_note --- ';
CREATE TABLE dbo.inv_document_lineitm_note(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
invctl_document_id VARCHAR(60) NOT NULL,
invctl_document_line_nbr INT NOT NULL,
note_id BIGINT NOT NULL,
note_timestamp DATETIME,
note_type VARCHAR(60),
note_text VARCHAR(MAX),
record_creation_type VARCHAR(60),
creator_party_id BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_document_lineitm_note PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, document_typcode, invctl_document_id, invctl_document_line_nbr, note_id))
GO
EXEC CREATE_PROPERTY_TABLE inv_document_lineitm_note;
GO
PRINT '--- CREATING inv_document_notes --- ';
CREATE TABLE dbo.inv_document_notes(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
invctl_document_id VARCHAR(60) NOT NULL,
note_id BIGINT NOT NULL,
note_timestamp DATETIME,
note_text VARCHAR(MAX),
creator_party_id BIGINT,
note_type VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_document_notes PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, document_typcode, invctl_document_id, note_id))
GO
EXEC CREATE_PROPERTY_TABLE inv_document_notes;
GO
PRINT '--- CREATING inv_invctl_doc_lineserial --- ';
CREATE TABLE dbo.inv_invctl_doc_lineserial(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
invctl_document_id VARCHAR(60) NOT NULL,
invctl_document_line_nbr INT NOT NULL,
serial_line_nbr INT NOT NULL,
serial_nbr VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_invctl_doc_lineserial PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, document_typcode, invctl_document_id, invctl_document_line_nbr, serial_line_nbr))
GO
EXEC CREATE_PROPERTY_TABLE inv_invctl_doc_lineserial;
GO
PRINT '--- CREATING inv_invctl_document --- ';
CREATE TABLE dbo.inv_invctl_document(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
invctl_document_id VARCHAR(60) NOT NULL,
create_date_timestamp DATETIME,
complete_date_timestamp DATETIME,
status_code VARCHAR(30),
originator_id VARCHAR(60),
document_subtypcode VARCHAR(30),
originator_name VARCHAR(254),
last_activity_date DATETIME,
po_ref_nbr VARCHAR(254),
record_creation_type VARCHAR(30),
description VARCHAR(254),
control_number VARCHAR(254),
originator_address_id VARCHAR(60),
submit_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_invctl_document PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, document_typcode, invctl_document_id))
GO
EXEC CREATE_PROPERTY_TABLE inv_invctl_document;
GO
PRINT '--- CREATING inv_invctl_document_lineitm --- ';
CREATE TABLE dbo.inv_invctl_document_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
invctl_document_id VARCHAR(60) NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
invctl_document_line_nbr INT NOT NULL,
carton_id VARCHAR(60),
inventory_item_id VARCHAR(60),
lineitm_typcode VARCHAR(30),
unit_count DECIMAL(14, 4),
lineitm_rtl_loc_id INT,
lineitm_wkstn_id BIGINT,
lineitm_business_date DATETIME,
lineitm_trans_seq BIGINT,
lineitm_rtrans_lineitm_seq INT,
status_code VARCHAR(30),
original_loc_id VARCHAR(60),
original_bucket_id VARCHAR(60),
expected_count DECIMAL(14, 4),
posted_count DECIMAL(14, 4),
record_creation_type VARCHAR(30),
entered_item_id VARCHAR(60),
entered_item_description VARCHAR(254),
serial_number VARCHAR(254),
retail DECIMAL(17, 6),
model_nbr VARCHAR(254),
control_number VARCHAR(254),
shipping_weight DECIMAL(12, 3),
unit_cost DECIMAL(17, 6),
posted_cost DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_invctl_document_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, invctl_document_id, document_typcode, invctl_document_line_nbr))
GO
PRINT '--- CREATING IDX_INV_INVCTL_DOC_LINEITM01 --- ';
CREATE INDEX IDX_INV_INVCTL_DOC_LINEITM01 ON dbo.inv_invctl_document_lineitm(organization_id, lineitm_rtl_loc_id, lineitm_business_date, lineitm_wkstn_id, lineitm_trans_seq, lineitm_rtrans_lineitm_seq)
GO

EXEC CREATE_PROPERTY_TABLE inv_invctl_document_lineitm;
GO
PRINT '--- CREATING inv_invctl_document_xref --- ';
CREATE TABLE dbo.inv_invctl_document_xref(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
invctl_document_id VARCHAR(60) NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
invctl_document_line_nbr INT NOT NULL,
cross_ref_organization_id INT,
cross_ref_document_id VARCHAR(60),
cross_ref_line_number INT,
cross_ref_document_typcode VARCHAR(30),
cross_ref_rtl_loc_id INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_invctl_document_xref PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, invctl_document_id, document_typcode, invctl_document_line_nbr))
GO
EXEC CREATE_PROPERTY_TABLE inv_invctl_document_xref;
GO
PRINT '--- CREATING inv_invctl_trans --- ';
CREATE TABLE dbo.inv_invctl_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
document_typcode VARCHAR(30),
document_date DATETIME,
old_status_code VARCHAR(30),
new_status_code VARCHAR(30),
invctl_document_id VARCHAR(60),
invctl_document_rtl_loc_id INT,
invctl_trans_reascode VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_invctl_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING inv_invctl_trans_detail --- ';
CREATE TABLE dbo.inv_invctl_trans_detail(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
invctl_trans_seq BIGINT NOT NULL,
invctl_document_rtl_loc_id INT,
invctl_document_id VARCHAR(60),
document_typcode VARCHAR(30),
invctl_document_line_nbr INT,
item_id VARCHAR(60),
action_code VARCHAR(30),
previous_unit_count DECIMAL(14, 4),
new_unit_count DECIMAL(14, 4),
old_status_code VARCHAR(30),
new_status_code VARCHAR(30),
previous_posted_count DECIMAL(14, 4),
new_posted_count DECIMAL(14, 4),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_invctl_trans_detail PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, invctl_trans_seq))
GO
EXEC CREATE_PROPERTY_TABLE inv_invctl_trans_detail;
GO
PRINT '--- CREATING inv_inventory_journal --- ';
CREATE TABLE dbo.inv_inventory_journal(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
trans_lineitm_seq INT NOT NULL,
journal_seq BIGINT NOT NULL,
inventory_item_id VARCHAR(60),
item_serial_nbr VARCHAR(254),
action_code VARCHAR(30),
quantity DECIMAL(11, 4),
source_location_id VARCHAR(60),
source_bucket_id VARCHAR(60),
dest_location_id VARCHAR(60),
dest_bucket_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_inventory_journal PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, trans_lineitm_seq, journal_seq))
GO
EXEC CREATE_PROPERTY_TABLE inv_inventory_journal;
GO
PRINT '--- CREATING inv_inventory_loc_mod --- ';
CREATE TABLE dbo.inv_inventory_loc_mod(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
document_id VARCHAR(60) NOT NULL,
document_line_nbr INT NOT NULL,
mod_seq INT NOT NULL,
serial_nbr VARCHAR(254),
source_location_id VARCHAR(60),
source_bucket_id VARCHAR(60),
dest_location_id VARCHAR(60),
dest_bucket_id VARCHAR(60),
quantity DECIMAL(11, 4),
action_code VARCHAR(30),
item_id VARCHAR(60),
cost DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_inventory_loc_mod PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, document_typcode, document_id, document_line_nbr, mod_seq))
GO
EXEC CREATE_PROPERTY_TABLE inv_inventory_loc_mod;
GO
PRINT '--- CREATING inv_item_acct_mod --- ';
CREATE TABLE dbo.inv_item_acct_mod(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
invctl_document_id VARCHAR(60) NOT NULL,
invctl_document_line_nbr INT NOT NULL,
cust_acct_code VARCHAR(30) NOT NULL,
cust_acct_id VARCHAR(60) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_item_acct_mod PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, document_typcode, invctl_document_id, invctl_document_line_nbr))
GO
EXEC CREATE_PROPERTY_TABLE inv_item_acct_mod;
GO
PRINT '--- CREATING inv_location --- ';
CREATE TABLE dbo.inv_location(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
inv_location_id VARCHAR(60) NOT NULL,
name VARCHAR(254),
active_flag BIT DEFAULT (0),
system_location_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_location PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, inv_location_id))
GO
EXEC CREATE_PROPERTY_TABLE inv_location;
GO
PRINT '--- CREATING inv_location_availability --- ';
CREATE TABLE dbo.inv_location_availability(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
location_id VARCHAR(60) NOT NULL,
availability_code VARCHAR(30) NOT NULL,
privilege_type VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_location_availability PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, location_id, availability_code))
GO
EXEC CREATE_PROPERTY_TABLE inv_location_availability;
GO
PRINT '--- CREATING inv_location_bucket --- ';
CREATE TABLE dbo.inv_location_bucket(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
location_id VARCHAR(60) NOT NULL,
bucket_id VARCHAR(60) NOT NULL,
tracking_method VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_location_bucket PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, location_id, bucket_id))
GO
EXEC CREATE_PROPERTY_TABLE inv_location_bucket;
GO
PRINT '--- CREATING inv_movement_pending --- ';
CREATE TABLE dbo.inv_movement_pending(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
trans_lineitm_seq INT NOT NULL,
item_id VARCHAR(60),
serial_nbr VARCHAR(254),
action_code VARCHAR(30),
quantity DECIMAL(11, 4),
reconciled_flag BIT DEFAULT (0),
void_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_movement_pending PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, trans_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE inv_movement_pending;
GO
PRINT '--- CREATING inv_movement_pending_detail --- ';
CREATE TABLE dbo.inv_movement_pending_detail(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
trans_lineitm_seq INT NOT NULL,
pending_seq INT NOT NULL,
serial_nbr VARCHAR(254),
quantity DECIMAL(11, 4),
source_location_id VARCHAR(60),
source_bucket_id VARCHAR(60),
dest_location_id VARCHAR(60),
dest_bucket_id VARCHAR(60),
action_code VARCHAR(30),
void_flag BIT DEFAULT (0),
item_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_movement_pending_detail PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, trans_lineitm_seq, pending_seq))
GO
EXEC CREATE_PROPERTY_TABLE inv_movement_pending_detail;
GO
PRINT '--- CREATING inv_mptrans_lineitm --- ';
CREATE TABLE dbo.inv_mptrans_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
trans_lineitm_seq INT NOT NULL,
original_rtl_loc_id INT,
original_wkstn_id BIGINT,
original_business_date DATETIME,
original_trans_seq BIGINT,
original_trans_lineitm_seq INT,
quantity_reconciled DECIMAL(11, 4),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_mptrans_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, trans_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE inv_mptrans_lineitm;
GO
PRINT '--- CREATING inv_rep_document_lineitm --- ';
CREATE TABLE dbo.inv_rep_document_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
invctl_document_id VARCHAR(60) NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
invctl_document_line_nbr INT NOT NULL,
suggested_order_qty DECIMAL(11, 4),
order_quantity DECIMAL(11, 4),
confirmed_quantity DECIMAL(11, 4),
confirmation_date DATETIME,
confirmation_number VARCHAR(60),
ship_via VARCHAR(254),
shipped_quantity DECIMAL(11, 4),
shipped_date DATETIME,
received_quantity DECIMAL(11, 4),
received_date DATETIME,
source_type VARCHAR(60),
source_id VARCHAR(60),
source_name VARCHAR(254),
parent_document_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_rep_document_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, invctl_document_id, document_typcode, invctl_document_line_nbr))
GO
EXEC CREATE_PROPERTY_TABLE inv_rep_document_lineitm;
GO
PRINT '--- CREATING inv_serialized_stock_ledger --- ';
CREATE TABLE dbo.inv_serialized_stock_ledger(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
inv_location_id VARCHAR(60) NOT NULL,
bucket_id VARCHAR(60) NOT NULL,
item_id VARCHAR(60) NOT NULL,
serial_nbr VARCHAR(200) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_serialized_stock_ledger PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, inv_location_id, bucket_id, item_id, serial_nbr))
GO
EXEC CREATE_PROPERTY_TABLE inv_serialized_stock_ledger;
GO
PRINT '--- CREATING inv_shipment --- ';
CREATE TABLE dbo.inv_shipment(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
invctl_document_id VARCHAR(60) NOT NULL,
shipment_seq INT NOT NULL,
expected_delivery_date DATETIME,
actual_delivery_date DATETIME,
expected_ship_date DATETIME,
destination_party_id BIGINT,
shipping_carrier VARCHAR(254),
actual_ship_date DATETIME,
tracking_nbr VARCHAR(254),
shipment_statcode VARCHAR(30),
record_creation_type VARCHAR(30),
destination_rtl_loc_id INT,
destination_name VARCHAR(254),
shipping_method VARCHAR(254),
shipping_label VARCHAR(4000),
destination_type VARCHAR(30),
destination_service_loc_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_shipment PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, document_typcode, invctl_document_id, shipment_seq))
GO
EXEC CREATE_PROPERTY_TABLE inv_shipment;
GO
PRINT '--- CREATING inv_shipment_address --- ';
CREATE TABLE dbo.inv_shipment_address(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
invctl_document_id VARCHAR(60) NOT NULL,
shipment_seq INT NOT NULL,
address1 VARCHAR(254),
address2 VARCHAR(254),
address3 VARCHAR(254),
address4 VARCHAR(254),
apartment VARCHAR(30),
city VARCHAR(254),
state VARCHAR(30),
postal_code VARCHAR(30),
country VARCHAR(2),
neighborhood VARCHAR(254),
county VARCHAR(254),
telephone1 VARCHAR(32),
telephone2 VARCHAR(32),
telephone3 VARCHAR(32),
telephone4 VARCHAR(32),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_shipment_address PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, document_typcode, invctl_document_id, shipment_seq))
GO
EXEC CREATE_PROPERTY_TABLE inv_shipment_address;
GO
PRINT '--- CREATING inv_shipment_lines --- ';
CREATE TABLE dbo.inv_shipment_lines(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
invctl_document_id VARCHAR(60) NOT NULL,
shipment_seq INT NOT NULL,
lineitm_seq INT NOT NULL,
invctl_document_line_nbr INT NOT NULL,
ship_qty DECIMAL(11, 4),
carton_id VARCHAR(60),
status_code VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_shipment_lines PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, document_typcode, invctl_document_id, shipment_seq, lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE inv_shipment_lines;
GO
PRINT '--- CREATING inv_shipper --- ';
CREATE TABLE dbo.inv_shipper(
organization_id INT NOT NULL,
shipper_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
shipper_desc VARCHAR(254),
display_order INT,
tracking_number_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_shipper PRIMARY KEY CLUSTERED (organization_id, shipper_id))
GO
PRINT '--- CREATING IDX_INV_SHIPPER_ORGNODE --- ';
CREATE INDEX IDX_INV_SHIPPER_ORGNODE ON dbo.inv_shipper(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE inv_shipper;
GO
PRINT '--- CREATING inv_shipper_method --- ';
CREATE TABLE dbo.inv_shipper_method(
organization_id INT NOT NULL,
shipper_method_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
shipper_method_desc VARCHAR(254),
shipper_id VARCHAR(60),
domestic_service_code VARCHAR(60),
intl_service_code VARCHAR(60),
display_order INT,
priority INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_shipper_method PRIMARY KEY CLUSTERED (organization_id, shipper_method_id))
GO
PRINT '--- CREATING IDX_INV_SHIPPER_METHOD_ORGNODE --- ';
CREATE INDEX IDX_INV_SHIPPER_METHOD_ORGNODE ON dbo.inv_shipper_method(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE inv_shipper_method;
GO
PRINT '--- CREATING inv_stock_fiscal_year --- ';
CREATE TABLE dbo.inv_stock_fiscal_year(
organization_id INT NOT NULL,
fiscal_year INT NOT NULL,
start_date DATETIME,
end_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_stock_fiscal_year PRIMARY KEY CLUSTERED (organization_id, fiscal_year))
GO
EXEC CREATE_PROPERTY_TABLE inv_stock_fiscal_year;
GO
PRINT '--- CREATING inv_stock_ledger_acct --- ';
CREATE TABLE dbo.inv_stock_ledger_acct(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
inv_location_id VARCHAR(60) NOT NULL,
bucket_id VARCHAR(60) NOT NULL,
item_id VARCHAR(60) NOT NULL,
unitcount DECIMAL(14, 4),
inventory_value DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_stock_ledger_acct PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, inv_location_id, bucket_id, item_id))
GO
PRINT '--- CREATING IDX_INV_STOCK_LEDGER_ACCT01 --- ';
CREATE INDEX IDX_INV_STOCK_LEDGER_ACCT01 ON dbo.inv_stock_ledger_acct(organization_id, bucket_id, item_id, rtl_loc_id, unitcount)
GO

EXEC CREATE_PROPERTY_TABLE inv_stock_ledger_acct;
GO
PRINT '--- CREATING inv_sum_count_trans_dtl --- ';
CREATE TABLE dbo.inv_sum_count_trans_dtl(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
trans_line_seq INT NOT NULL,
location_id VARCHAR(60),
bucket_id VARCHAR(60),
system_count DECIMAL(14, 4),
declared_count DECIMAL(14, 4),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_sum_count_trans_dtl PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, trans_line_seq))
GO
EXEC CREATE_PROPERTY_TABLE inv_sum_count_trans_dtl;
GO
PRINT '--- CREATING inv_valid_destinations --- ';
CREATE TABLE dbo.inv_valid_destinations(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
document_typcode VARCHAR(30) NOT NULL,
document_subtypcode VARCHAR(30) NOT NULL,
destination_type_enum VARCHAR(30) NOT NULL,
destination_id VARCHAR(60) NOT NULL,
description VARCHAR(254),
sort_order INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_inv_valid_destinations PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, document_typcode, document_subtypcode, destination_type_enum, destination_id))
GO
EXEC CREATE_PROPERTY_TABLE inv_valid_destinations;
GO
PRINT '--- CREATING itm_attached_items --- ';
CREATE TABLE dbo.itm_attached_items(
organization_id INT NOT NULL,
sold_item_id VARCHAR(60) NOT NULL,
attached_item_id VARCHAR(60) NOT NULL,
level_code VARCHAR(30) DEFAULT ('*') NOT NULL,
level_value VARCHAR(60) DEFAULT ('*') NOT NULL,
begin_datetime DATETIME,
end_datetime DATETIME,
prompt_to_add_flag BIT DEFAULT (0),
prompt_to_add_msg_key VARCHAR(254),
quantity_to_add DECIMAL(11, 4),
lineitm_assoc_typcode VARCHAR(30),
prompt_for_return_flag BIT DEFAULT (0),
prompt_for_return_msg_key VARCHAR(254),
external_id VARCHAR(60),
external_system VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_attached_items PRIMARY KEY CLUSTERED (organization_id, sold_item_id, attached_item_id, level_code, level_value))
GO
EXEC CREATE_PROPERTY_TABLE itm_attached_items;
GO
PRINT '--- CREATING itm_item --- ';
CREATE TABLE dbo.itm_item(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
name VARCHAR(254),
description VARCHAR(254),
merch_level_1 VARCHAR(60) DEFAULT ('DEFAULT'),
merch_level_2 VARCHAR(60),
merch_level_3 VARCHAR(60),
merch_level_4 VARCHAR(60),
list_price DECIMAL(17, 6),
measure_req_flag BIT DEFAULT (0),
item_lvlcode VARCHAR(30),
parent_item_id VARCHAR(60),
not_inventoried_flag BIT DEFAULT (0),
serialized_item_flag BIT DEFAULT (0),
item_typcode VARCHAR(30),
dtv_class_name VARCHAR(254),
dimension_system VARCHAR(60),
disallow_matrix_display_flag BIT DEFAULT (0),
item_matrix_color VARCHAR(20),
dimension1 VARCHAR(60),
dimension2 VARCHAR(60),
dimension3 VARCHAR(60),
external_system VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item PRIMARY KEY CLUSTERED (organization_id, item_id))
GO
PRINT '--- CREATING XST_ITM_ITEM_MRCHLVL1 --- ';
CREATE INDEX XST_ITM_ITEM_MRCHLVL1 ON dbo.itm_item(organization_id, merch_level_1)
GO

PRINT '--- CREATING XST_ITM_ITEM_MRCHLVL2 --- ';
CREATE INDEX XST_ITM_ITEM_MRCHLVL2 ON dbo.itm_item(organization_id, merch_level_2)
GO

PRINT '--- CREATING XST_ITM_ITEM_MRCHLVL3 --- ';
CREATE INDEX XST_ITM_ITEM_MRCHLVL3 ON dbo.itm_item(organization_id, merch_level_3)
GO

PRINT '--- CREATING XST_ITM_ITEM_MRCHLVL4 --- ';
CREATE INDEX XST_ITM_ITEM_MRCHLVL4 ON dbo.itm_item(organization_id, merch_level_4)
GO

PRINT '--- CREATING XST_ITM_ITEM_DESCRIPTION --- ';
CREATE INDEX XST_ITM_ITEM_DESCRIPTION ON dbo.itm_item(organization_id, description)
GO

PRINT '--- CREATING XST_ITM_ITEM_ID_PARENTID --- ';
CREATE INDEX XST_ITM_ITEM_ID_PARENTID ON dbo.itm_item(organization_id, parent_item_id, item_id)
GO

PRINT '--- CREATING XST_ITM_ITEM_TYPCODE --- ';
CREATE INDEX XST_ITM_ITEM_TYPCODE ON dbo.itm_item(organization_id, item_typcode)
GO

PRINT '--- CREATING IDX_ITM_ITEM02 --- ';
CREATE INDEX IDX_ITM_ITEM02 ON dbo.itm_item(item_id, item_typcode, merch_level_1, organization_id)
GO

PRINT '--- CREATING IDX_ITM_ITEM_ORGNODE --- ';
CREATE INDEX IDX_ITM_ITEM_ORGNODE ON dbo.itm_item(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_item;
GO
PRINT '--- CREATING itm_item_cross_reference --- ';
CREATE TABLE dbo.itm_item_cross_reference(
organization_id INT NOT NULL,
manufacturer_upc VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
item_id VARCHAR(60),
manufacturer VARCHAR(254),
primary_flag BIT DEFAULT (0) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item_cross_reference PRIMARY KEY CLUSTERED (organization_id, manufacturer_upc))
GO
PRINT '--- CREATING XST_ITM_XREF_ITEMID --- ';
CREATE INDEX XST_ITM_XREF_ITEMID ON dbo.itm_item_cross_reference(organization_id, item_id)
GO

PRINT '--- CREATING XST_ITM_XREF_UPC_ITEMID --- ';
CREATE INDEX XST_ITM_XREF_UPC_ITEMID ON dbo.itm_item_cross_reference(manufacturer_upc, item_id, organization_id)
GO

PRINT '--- CREATING IDX_ITM_ITEM_XREFERENCEORGNODE --- ';
CREATE INDEX IDX_ITM_ITEM_XREFERENCEORGNODE ON dbo.itm_item_cross_reference(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_item_cross_reference;
GO
PRINT '--- CREATING itm_item_deal_prop --- ';
CREATE TABLE dbo.itm_item_deal_prop(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
itm_deal_property_code VARCHAR(30) NOT NULL,
effective_date DATETIME NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
expiration_date DATETIME,
type VARCHAR(30),
string_value VARCHAR(254),
date_value DATETIME,
decimal_value DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item_deal_prop PRIMARY KEY CLUSTERED (organization_id, item_id, itm_deal_property_code, effective_date))
GO
PRINT '--- CREATING XST_ITM_ITEMPROPS_ITEMID --- ';
CREATE INDEX XST_ITM_ITEMPROPS_ITEMID ON dbo.itm_item_deal_prop(organization_id, item_id)
GO

PRINT '--- CREATING IDX_ITM_ITEM_PROP_ORGNODE --- ';
CREATE INDEX IDX_ITM_ITEM_PROP_ORGNODE ON dbo.itm_item_deal_prop(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_item_deal_prop;
GO
PRINT '--- CREATING itm_item_dimension_type --- ';
CREATE TABLE dbo.itm_item_dimension_type(
organization_id INT NOT NULL,
dimension_system VARCHAR(60) NOT NULL,
dimension VARCHAR(30) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
seq INT,
sort_order INT,
description VARCHAR(254),
prompt_msg VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item_dimension_type PRIMARY KEY CLUSTERED (organization_id, dimension_system, dimension))
GO
PRINT '--- CREATING IDX_ITM_ITEM_DIM_TYPE_ORGNODE --- ';
CREATE INDEX IDX_ITM_ITEM_DIM_TYPE_ORGNODE ON dbo.itm_item_dimension_type(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_item_dimension_type;
GO
PRINT '--- CREATING itm_item_dimension_value --- ';
CREATE TABLE dbo.itm_item_dimension_value(
organization_id INT NOT NULL,
dimension_system VARCHAR(60) NOT NULL,
dimension VARCHAR(30) NOT NULL,
value VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
sort_order INT,
description VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item_dimension_value PRIMARY KEY CLUSTERED (organization_id, dimension_system, dimension, value))
GO
PRINT '--- CREATING IDX_ITM_ITEM_DIM_VALUE_ORGNODE --- ';
CREATE INDEX IDX_ITM_ITEM_DIM_VALUE_ORGNODE ON dbo.itm_item_dimension_value(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_item_dimension_value;
GO
PRINT '--- CREATING itm_item_images --- ';
CREATE TABLE dbo.itm_item_images(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
feature_id VARCHAR(60) DEFAULT ('DEFAULT') NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
image_url VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item_images PRIMARY KEY CLUSTERED (organization_id, item_id, feature_id))
GO
EXEC CREATE_PROPERTY_TABLE itm_item_images;
GO
PRINT '--- CREATING itm_item_label_batch --- ';
CREATE TABLE dbo.itm_item_label_batch(
organization_id INT NOT NULL,
batch_name VARCHAR(30) NOT NULL,
item_id VARCHAR(60) NOT NULL,
stock_label VARCHAR(20) NOT NULL,
rtl_loc_id INT DEFAULT (0) NOT NULL,
count INT NOT NULL,
overriden_price DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item_label_batch PRIMARY KEY CLUSTERED (organization_id, batch_name, item_id, stock_label, rtl_loc_id))
GO
EXEC CREATE_PROPERTY_TABLE itm_item_label_batch;
GO
PRINT '--- CREATING itm_item_label_properties --- ';
CREATE TABLE dbo.itm_item_label_properties(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
stock_label VARCHAR(30),
logo_url VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item_label_properties PRIMARY KEY CLUSTERED (organization_id, item_id))
GO
PRINT '--- CREATING IDX_ITM_ITEM_LABL_PROP_ORGNODE --- ';
CREATE INDEX IDX_ITM_ITEM_LABL_PROP_ORGNODE ON dbo.itm_item_label_properties(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_item_label_properties;
GO
PRINT '--- CREATING itm_item_msg --- ';
CREATE TABLE dbo.itm_item_msg(
organization_id INT NOT NULL,
msg_id VARCHAR(60) NOT NULL,
effective_datetime DATETIME NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
expr_datetime DATETIME,
msg_key VARCHAR(254) NOT NULL,
title_key VARCHAR(254),
content_type VARCHAR(30),
contents VARBINARY(MAX),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item_msg PRIMARY KEY CLUSTERED (organization_id, msg_id, effective_datetime))
GO
PRINT '--- CREATING IDX_ITM_ITEM_MSG_ORGNODE --- ';
CREATE INDEX IDX_ITM_ITEM_MSG_ORGNODE ON dbo.itm_item_msg(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_item_msg;
GO
PRINT '--- CREATING itm_item_msg_cross_reference --- ';
CREATE TABLE dbo.itm_item_msg_cross_reference(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
msg_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item_msg_cross_reference PRIMARY KEY CLUSTERED (organization_id, item_id, msg_id))
GO
PRINT '--- CREATING IDX_ITM_ITEM_MSG_XREF_ORGNODE --- ';
CREATE INDEX IDX_ITM_ITEM_MSG_XREF_ORGNODE ON dbo.itm_item_msg_cross_reference(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_item_msg_cross_reference;
GO
PRINT '--- CREATING itm_item_msg_types --- ';
CREATE TABLE dbo.itm_item_msg_types(
organization_id INT NOT NULL,
msg_id VARCHAR(60) NOT NULL,
sale_lineitm_typcode VARCHAR(30) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item_msg_types PRIMARY KEY CLUSTERED (organization_id, msg_id, sale_lineitm_typcode))
GO
PRINT '--- CREATING IDX_ITM_ITEM_MSG_TYPES_ORGNODE --- ';
CREATE INDEX IDX_ITM_ITEM_MSG_TYPES_ORGNODE ON dbo.itm_item_msg_types(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_item_msg_types;
GO
PRINT '--- CREATING itm_item_options --- ';
CREATE TABLE dbo.itm_item_options(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
level_code VARCHAR(30) DEFAULT ('*') NOT NULL,
level_value VARCHAR(60) DEFAULT ('*') NOT NULL,
unit_cost DECIMAL(17, 6),
curr_sale_price DECIMAL(17, 6),
unit_of_measure_code VARCHAR(30),
compare_at_price DECIMAL(17, 6),
min_sale_unit_count DECIMAL(11, 4),
max_sale_unit_count DECIMAL(11, 4),
item_availability_code VARCHAR(30),
disallow_discounts_flag BIT DEFAULT (0),
prompt_for_quantity_flag BIT DEFAULT (0),
prompt_for_price_flag BIT DEFAULT (0),
prompt_for_description_flag BIT DEFAULT (0),
force_quantity_of_one_flag BIT DEFAULT (0),
not_returnable_flag BIT DEFAULT (0),
no_giveaways_flag BIT DEFAULT (0),
attached_items_flag BIT DEFAULT (0),
substitute_available_flag BIT DEFAULT (0),
tax_group_id VARCHAR(60),
messages_flag BIT DEFAULT (0),
vendor VARCHAR(256),
season_code VARCHAR(30),
part_number VARCHAR(254),
qty_scale INT,
restocking_fee DECIMAL(17, 6),
special_order_lead_days INT,
apply_restocking_fee_flag BIT DEFAULT (0),
disallow_send_sale_flag BIT DEFAULT (0),
disallow_price_change_flag BIT DEFAULT (0),
disallow_layaway_flag BIT DEFAULT (0),
disallow_special_order_flag BIT DEFAULT (0),
disallow_self_checkout_flag BIT DEFAULT (0),
disallow_work_order_flag BIT DEFAULT (0),
disallow_commission_flag BIT DEFAULT (0),
warranty_flag BIT DEFAULT (0),
generic_item_flag BIT DEFAULT (0),
initial_sale_qty DECIMAL(11, 4),
disposition_code VARCHAR(30),
foodstamp_eligible_flag BIT DEFAULT (0),
stock_status VARCHAR(60),
prompt_for_customer VARCHAR(30),
shipping_weight DECIMAL(12, 3),
disallow_order_flag BIT DEFAULT (0),
disallow_deals_flag BIT DEFAULT (0),
pack_size DECIMAL(11, 4),
default_source_type VARCHAR(60),
default_source_id VARCHAR(60),
disallow_rain_check BIT DEFAULT (0),
selling_group_id VARCHAR(60),
fiscal_item_id VARCHAR(254),
fiscal_item_description VARCHAR(254),
exclude_from_net_sales_flag BIT DEFAULT (0),
external_system VARCHAR(60),
tare_value DECIMAL(11, 4),
tare_unit_of_measure_code VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item_options PRIMARY KEY CLUSTERED (organization_id, item_id, level_code, level_value))
GO
PRINT '--- CREATING IDX_ITM_ITEM_OPTIONS --- ';
CREATE INDEX IDX_ITM_ITEM_OPTIONS ON dbo.itm_item_options(organization_id, item_id)
GO

EXEC CREATE_PROPERTY_TABLE itm_item_options;
GO
PRINT '--- CREATING itm_item_prices --- ';
CREATE TABLE dbo.itm_item_prices(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
level_code VARCHAR(30) DEFAULT ('*') NOT NULL,
level_value VARCHAR(60) DEFAULT ('*') NOT NULL,
itm_price_property_code VARCHAR(60) NOT NULL,
effective_date DATETIME NOT NULL,
expiration_date DATETIME,
price DECIMAL(17, 6) NOT NULL,
price_qty DECIMAL(11, 4) DEFAULT (1) NOT NULL,
external_id VARCHAR(60),
external_system VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item_prices PRIMARY KEY CLUSTERED (organization_id, item_id, level_code, level_value, itm_price_property_code, effective_date, price_qty))
GO
PRINT '--- CREATING XST_ITM_ITEMPRICES_EXPR --- ';
CREATE INDEX XST_ITM_ITEMPRICES_EXPR ON dbo.itm_item_prices(expiration_date)
GO

EXEC CREATE_PROPERTY_TABLE itm_item_prices;
GO
PRINT '--- CREATING itm_item_prompt_properties --- ';
CREATE TABLE dbo.itm_item_prompt_properties(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
itm_prompt_property_code VARCHAR(30) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
code_group VARCHAR(30),
prompt_title_key VARCHAR(60),
prompt_msg_key VARCHAR(60),
required_flag BIT DEFAULT (0),
sort_order INT,
prompt_mthd_code VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_item_prompt_properties PRIMARY KEY CLUSTERED (organization_id, item_id, itm_prompt_property_code))
GO
PRINT '--- CREATING IDX_ITM_ITM_PRMPT_PROP_ORGNODE --- ';
CREATE INDEX IDX_ITM_ITM_PRMPT_PROP_ORGNODE ON dbo.itm_item_prompt_properties(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_item_prompt_properties;
GO
PRINT '--- CREATING itm_kit_component --- ';
CREATE TABLE dbo.itm_kit_component(
organization_id INT NOT NULL,
kit_item_id VARCHAR(60) NOT NULL,
component_item_id VARCHAR(60) NOT NULL,
seq_nbr INT DEFAULT (1) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
display_order INT,
quantity_per_kit INT DEFAULT (1),
begin_datetime DATETIME,
end_datetime DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_kit_component PRIMARY KEY CLUSTERED (organization_id, kit_item_id, component_item_id, seq_nbr))
GO
PRINT '--- CREATING IDX_ITM_KIT_COMPONENT_ORGNODE --- ';
CREATE INDEX IDX_ITM_KIT_COMPONENT_ORGNODE ON dbo.itm_kit_component(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_kit_component;
GO
PRINT '--- CREATING itm_matrix_sort_order --- ';
CREATE TABLE dbo.itm_matrix_sort_order(
organization_id INT NOT NULL,
matrix_sort_type VARCHAR(60) NOT NULL,
matrix_sort_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
sort_order INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_matrix_sort_order PRIMARY KEY CLUSTERED (organization_id, matrix_sort_type, matrix_sort_id))
GO
PRINT '--- CREATING IDX_ITM_MATRIX_SORTORD_ORGNODE --- ';
CREATE INDEX IDX_ITM_MATRIX_SORTORD_ORGNODE ON dbo.itm_matrix_sort_order(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_matrix_sort_order;
GO
PRINT '--- CREATING itm_merch_hierarchy --- ';
CREATE TABLE dbo.itm_merch_hierarchy(
organization_id INT NOT NULL,
hierarchy_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
parent_id VARCHAR(60),
level_code VARCHAR(30),
description VARCHAR(254),
sort_order INT,
hidden_flag BIT DEFAULT (0),
disallow_matrix_display_flag BIT DEFAULT (0),
item_matrix_color VARCHAR(20),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_merch_hierarchy PRIMARY KEY CLUSTERED (organization_id, hierarchy_id))
GO
PRINT '--- CREATING IDX_ITM_MERCH_HIRARCHY_ORGNODE --- ';
CREATE INDEX IDX_ITM_MERCH_HIRARCHY_ORGNODE ON dbo.itm_merch_hierarchy(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_merch_hierarchy;
GO
PRINT '--- CREATING itm_merch_hierarchy_levels --- ';
CREATE TABLE dbo.itm_merch_hierarchy_levels(
organization_id INT NOT NULL,
level_id INT NOT NULL,
level_code VARCHAR(30),
description VARCHAR(150),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_merch_hierarchy_levels PRIMARY KEY CLUSTERED (organization_id, level_id))
GO
EXEC CREATE_PROPERTY_TABLE itm_merch_hierarchy_levels;
GO
PRINT '--- CREATING itm_non_phys_item --- ';
CREATE TABLE dbo.itm_non_phys_item(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
display_order INT,
non_phys_item_typcode VARCHAR(30),
non_phys_item_subtype VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_non_phys_item PRIMARY KEY CLUSTERED (organization_id, item_id))
GO
PRINT '--- CREATING itm_quick_items --- ';
CREATE TABLE dbo.itm_quick_items(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
parent_id VARCHAR(60),
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
image_url VARCHAR(254),
sort_order INT,
description VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_quick_items PRIMARY KEY CLUSTERED (organization_id, item_id))
GO
EXEC CREATE_PROPERTY_TABLE itm_quick_items;
GO
PRINT '--- CREATING itm_refund_schedule --- ';
CREATE TABLE dbo.itm_refund_schedule(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
effective_date DATETIME NOT NULL,
expiration_date DATETIME,
max_full_refund_time INT,
min_no_refund_time INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_refund_schedule PRIMARY KEY CLUSTERED (organization_id, item_id, effective_date))
GO
PRINT '--- CREATING IDX_ITM_REFND_SCHEDULE_ORGNODE --- ';
CREATE INDEX IDX_ITM_REFND_SCHEDULE_ORGNODE ON dbo.itm_refund_schedule(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_refund_schedule;
GO
PRINT '--- CREATING itm_restrict_gs1 --- ';
CREATE TABLE dbo.itm_restrict_gs1(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
field_id VARCHAR(10) NOT NULL,
ai_type VARCHAR(30) NOT NULL,
start_value VARCHAR(50) NOT NULL,
end_value VARCHAR(50) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_restrict_gs1 PRIMARY KEY CLUSTERED (organization_id, item_id, field_id, start_value))
GO
PRINT '--- CREATING IDX_ITM_RESTRICT_GS1 --- ';
CREATE INDEX IDX_ITM_RESTRICT_GS1 ON dbo.itm_restrict_gs1(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_restrict_gs1;
GO
PRINT '--- CREATING itm_restriction --- ';
CREATE TABLE dbo.itm_restriction(
organization_id INT NOT NULL,
restriction_id VARCHAR(30) NOT NULL,
restriction_description VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_restriction PRIMARY KEY CLUSTERED (organization_id, restriction_id))
GO
EXEC CREATE_PROPERTY_TABLE itm_restriction;
GO
PRINT '--- CREATING itm_restriction_calendar --- ';
CREATE TABLE dbo.itm_restriction_calendar(
organization_id INT NOT NULL,
restriction_id VARCHAR(30) NOT NULL,
restriction_typecode VARCHAR(60) NOT NULL,
day_code VARCHAR(3) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
start_time DATETIME,
end_time DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_restriction_calendar PRIMARY KEY CLUSTERED (organization_id, restriction_id, restriction_typecode, day_code))
GO
PRINT '--- CREATING IDX_ITM_RESTRICT_CAL_ORGNODE --- ';
CREATE INDEX IDX_ITM_RESTRICT_CAL_ORGNODE ON dbo.itm_restriction_calendar(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_restriction_calendar;
GO
PRINT '--- CREATING itm_restriction_mapping --- ';
CREATE TABLE dbo.itm_restriction_mapping(
organization_id INT NOT NULL,
restriction_id VARCHAR(30) NOT NULL,
merch_hierarchy_level VARCHAR(60) NOT NULL,
merch_hierarchy_id VARCHAR(60) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_restriction_mapping PRIMARY KEY CLUSTERED (organization_id, restriction_id, merch_hierarchy_level, merch_hierarchy_id))
GO
EXEC CREATE_PROPERTY_TABLE itm_restriction_mapping;
GO
PRINT '--- CREATING itm_restriction_type --- ';
CREATE TABLE dbo.itm_restriction_type(
organization_id INT NOT NULL,
restriction_id VARCHAR(30) NOT NULL,
restriction_typecode VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
effective_date DATETIME,
expiration_date DATETIME,
value_type VARCHAR(30),
boolean_value BIT,
date_value DATETIME,
decimal_value DECIMAL(17, 6),
string_value VARCHAR(254),
exclude_returns_flag BIT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_restriction_type PRIMARY KEY CLUSTERED (organization_id, restriction_id, restriction_typecode))
GO
PRINT '--- CREATING IDX_ITM_RESTRICT_TYPE_ORGNODE --- ';
CREATE INDEX IDX_ITM_RESTRICT_TYPE_ORGNODE ON dbo.itm_restriction_type(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_restriction_type;
GO
PRINT '--- CREATING itm_substitute_items --- ';
CREATE TABLE dbo.itm_substitute_items(
organization_id INT NOT NULL,
primary_item_id VARCHAR(60) NOT NULL,
substitute_item_id VARCHAR(60) NOT NULL,
level_code VARCHAR(30) DEFAULT ('*') NOT NULL,
level_value VARCHAR(60) DEFAULT ('*') NOT NULL,
begin_datetime DATETIME,
end_datetime DATETIME,
external_id VARCHAR(60),
external_system VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_substitute_items PRIMARY KEY CLUSTERED (organization_id, primary_item_id, substitute_item_id, level_code, level_value))
GO
PRINT '--- CREATING IDX_ITM_SUB_ITEMS_ORGNODE --- ';
CREATE INDEX IDX_ITM_SUB_ITEMS_ORGNODE ON dbo.itm_substitute_items(level_code, level_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_substitute_items;
GO
PRINT '--- CREATING itm_vendor --- ';
CREATE TABLE dbo.itm_vendor(
organization_id INT NOT NULL,
vendor_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
name VARCHAR(254),
buyer VARCHAR(254),
address_id VARCHAR(60),
telephone VARCHAR(32),
contact_telephone VARCHAR(32),
typcode VARCHAR(30),
contact VARCHAR(254),
fax VARCHAR(32),
status VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_vendor PRIMARY KEY CLUSTERED (organization_id, vendor_id))
GO
PRINT '--- CREATING IDX_ITM_VENDOR_ORGNODE --- ';
CREATE INDEX IDX_ITM_VENDOR_ORGNODE ON dbo.itm_vendor(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_vendor;
GO
PRINT '--- CREATING itm_warranty --- ';
CREATE TABLE dbo.itm_warranty(
organization_id INT NOT NULL,
warranty_typcode VARCHAR(60) NOT NULL,
warranty_nbr VARCHAR(30) NOT NULL,
warranty_plan_id VARCHAR(60),
warranty_issue_date DATETIME,
warranty_expiration_date DATETIME,
status_code VARCHAR(30),
purchase_price DECIMAL(17, 6),
cust_id VARCHAR(60),
party_id BIGINT,
certificate_nbr VARCHAR(60),
certificate_company_name VARCHAR(254),
warranty_item_id VARCHAR(60),
warranty_line_business_date DATETIME,
warranty_line_rtl_loc_id INT,
warranty_line_wkstn_id BIGINT,
warranty_line_trans_seq BIGINT,
warranty_rtrans_lineitm_seq INT,
covered_item_id VARCHAR(60),
covered_line_business_date DATETIME,
covered_line_rtl_loc_id INT,
covered_line_wkstn_id BIGINT,
covered_line_trans_seq BIGINT,
covered_rtrans_lineitm_seq INT,
covered_item_purchase_date DATETIME,
covered_item_purchase_price DECIMAL(17, 6),
covered_item_purchase_location VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_warranty PRIMARY KEY CLUSTERED (organization_id, warranty_typcode, warranty_nbr))
GO
PRINT '--- CREATING IDX_ITM_WARRANTY01 --- ';
CREATE INDEX IDX_ITM_WARRANTY01 ON dbo.itm_warranty(party_id)
GO

EXEC CREATE_PROPERTY_TABLE itm_warranty;
GO
PRINT '--- CREATING itm_warranty_item --- ';
CREATE TABLE dbo.itm_warranty_item(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
pricing_mthd_code VARCHAR(60),
warranty_price_amt DECIMAL(17, 6),
warranty_price_percentage DECIMAL(6, 4),
warranty_min_price_amt DECIMAL(17, 6),
expiration_days INT,
service_days INT,
renewable_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_warranty_item PRIMARY KEY CLUSTERED (organization_id, item_id))
GO
PRINT '--- CREATING itm_warranty_item_price --- ';
CREATE TABLE dbo.itm_warranty_item_price(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
warranty_price_seq INT NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
min_item_price_amt DECIMAL(17, 6),
max_item_price_amt DECIMAL(17, 6),
price_amt DECIMAL(17, 6),
price_percentage DECIMAL(6, 4),
min_price_amt DECIMAL(17, 6),
ref_item_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_warranty_item_price PRIMARY KEY CLUSTERED (organization_id, item_id, warranty_price_seq))
GO
PRINT '--- CREATING IDXITMWARRANTYITEMPRICEORGNODE --- ';
CREATE INDEX IDXITMWARRANTYITEMPRICEORGNODE ON dbo.itm_warranty_item_price(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_warranty_item_price;
GO
PRINT '--- CREATING itm_warranty_item_xref --- ';
CREATE TABLE dbo.itm_warranty_item_xref(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
warranty_typcode VARCHAR(60) NOT NULL,
warranty_item_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
sort_order INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_warranty_item_xref PRIMARY KEY CLUSTERED (organization_id, item_id, warranty_typcode, warranty_item_id))
GO
PRINT '--- CREATING IDXITMWARRANTYITEMXREFORGNODE --- ';
CREATE INDEX IDXITMWARRANTYITEMXREFORGNODE ON dbo.itm_warranty_item_xref(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_warranty_item_xref;
GO
PRINT '--- CREATING itm_warranty_journal --- ';
CREATE TABLE dbo.itm_warranty_journal(
organization_id INT NOT NULL,
warranty_typcode VARCHAR(60) NOT NULL,
warranty_nbr VARCHAR(30) NOT NULL,
journal_seq BIGINT NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
trans_business_date DATETIME,
trans_rtl_loc_id INT,
trans_wkstn_id BIGINT,
trans_trans_seq BIGINT,
warranty_plan_id VARCHAR(60),
warranty_issue_date DATETIME,
warranty_expiration_date DATETIME,
status_code VARCHAR(30),
purchase_price DECIMAL(17, 6),
cust_id VARCHAR(60),
party_id BIGINT,
certificate_nbr VARCHAR(60),
certificate_company_name VARCHAR(254),
warranty_item_id VARCHAR(60),
warranty_line_business_date DATETIME,
warranty_line_rtl_loc_id INT,
warranty_line_wkstn_id BIGINT,
warranty_line_trans_seq BIGINT,
warranty_rtrans_lineitm_seq INT,
covered_item_id VARCHAR(60),
covered_line_business_date DATETIME,
covered_line_rtl_loc_id INT,
covered_line_wkstn_id BIGINT,
covered_line_trans_seq BIGINT,
covered_rtrans_lineitm_seq INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_itm_warranty_journal PRIMARY KEY CLUSTERED (organization_id, warranty_typcode, warranty_nbr, journal_seq))
GO
PRINT '--- CREATING IDX_ITM_WARRANTY_JOURNAL01 --- ';
CREATE INDEX IDX_ITM_WARRANTY_JOURNAL01 ON dbo.itm_warranty_journal(party_id)
GO

PRINT '--- CREATING IDXITMWARRANTYJOURNALORGNODE --- ';
CREATE INDEX IDXITMWARRANTYJOURNALORGNODE ON dbo.itm_warranty_journal(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE itm_warranty_journal;
GO
PRINT '--- CREATING loc_close_dates --- ';
CREATE TABLE dbo.loc_close_dates(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
close_date DATETIME NOT NULL,
reason_code VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_loc_close_dates PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, close_date))
GO
EXEC CREATE_PROPERTY_TABLE loc_close_dates;
GO
PRINT '--- CREATING loc_closing_message --- ';
CREATE TABLE dbo.loc_closing_message(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
closing_message VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_loc_closing_message PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id))
GO
EXEC CREATE_PROPERTY_TABLE loc_closing_message;
GO
PRINT '--- CREATING loc_cycle_question_answers --- ';
CREATE TABLE dbo.loc_cycle_question_answers(
organization_id INT NOT NULL,
question_id VARCHAR(60) NOT NULL,
answer_id VARCHAR(60) NOT NULL,
answer_timestamp DATETIME NOT NULL,
rtl_loc_id INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_loc_cycle_question_answers PRIMARY KEY CLUSTERED (organization_id, question_id, answer_id, answer_timestamp))
GO
EXEC CREATE_PROPERTY_TABLE loc_cycle_question_answers;
GO
PRINT '--- CREATING loc_cycle_question_choices --- ';
CREATE TABLE dbo.loc_cycle_question_choices(
organization_id INT NOT NULL,
question_id VARCHAR(60) NOT NULL,
answer_id VARCHAR(60) NOT NULL,
answer_text_key VARCHAR(MAX),
sort_order INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_loc_cycle_question_choices PRIMARY KEY CLUSTERED (organization_id, question_id, answer_id))
GO
EXEC CREATE_PROPERTY_TABLE loc_cycle_question_choices;
GO
PRINT '--- CREATING loc_cycle_questions --- ';
CREATE TABLE dbo.loc_cycle_questions(
organization_id INT NOT NULL,
question_id VARCHAR(60) NOT NULL,
question_text_key VARCHAR(254),
sort_order INT,
effective_datetime DATETIME,
expiration_datetime DATETIME,
rtl_loc_id INT DEFAULT (0),
corporate_message_flag BIT DEFAULT (0),
question_typcode VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_loc_cycle_questions PRIMARY KEY CLUSTERED (organization_id, question_id))
GO
EXEC CREATE_PROPERTY_TABLE loc_cycle_questions;
GO
PRINT '--- CREATING loc_legal_entity --- ';
CREATE TABLE dbo.loc_legal_entity(
organization_id INT NOT NULL,
legal_entity_id VARCHAR(30) NOT NULL,
description VARCHAR(254),
address1 VARCHAR(254),
address2 VARCHAR(254),
address3 VARCHAR(254),
address4 VARCHAR(254),
city VARCHAR(254),
state VARCHAR(30),
district VARCHAR(30),
area VARCHAR(30),
postal_code VARCHAR(30),
country VARCHAR(2),
neighborhood VARCHAR(254),
county VARCHAR(254),
apartment VARCHAR(30),
email_addr VARCHAR(254),
tax_id VARCHAR(30),
fiscal_code VARCHAR(30),
taxation_regime VARCHAR(30),
legal_employer_id VARCHAR(30),
activity_code VARCHAR(30),
tax_office_code VARCHAR(30),
statistical_code VARCHAR(30),
legal_form VARCHAR(60),
social_capital VARCHAR(60),
companies_register_number VARCHAR(30),
fax_number VARCHAR(32),
phone_number VARCHAR(32),
web_site VARCHAR(254),
establishment_code VARCHAR(30),
registration_city VARCHAR(254),
activity_description VARCHAR(254),
company_business_name VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_loc_legal_entity PRIMARY KEY CLUSTERED (organization_id, legal_entity_id))
GO
EXEC CREATE_PROPERTY_TABLE loc_legal_entity;
GO
PRINT '--- CREATING loc_org_hierarchy --- ';
CREATE TABLE dbo.loc_org_hierarchy(
organization_id INT NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
parent_code VARCHAR(30),
parent_value VARCHAR(60),
description VARCHAR(254),
level_mgr VARCHAR(254),
level_order INT,
sort_order INT,
inactive_flag BIT DEFAULT (0) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_loc_org_hierarchy PRIMARY KEY CLUSTERED (organization_id, org_code, org_value))
GO
PRINT '--- CREATING XST_LOC_ORGHIER_LVLMGR --- ';
CREATE INDEX XST_LOC_ORGHIER_LVLMGR ON dbo.loc_org_hierarchy(level_mgr)
GO

PRINT '--- CREATING XST_LOC_ORGHIER_LVLORDER --- ';
CREATE INDEX XST_LOC_ORGHIER_LVLORDER ON dbo.loc_org_hierarchy(level_order)
GO

PRINT '--- CREATING XST_LOC_ORGHIER_PARENT --- ';
CREATE INDEX XST_LOC_ORGHIER_PARENT ON dbo.loc_org_hierarchy(parent_code, parent_value)
GO

PRINT '--- CREATING XST_LOC_ORGHIER_SORTORDER --- ';
CREATE INDEX XST_LOC_ORGHIER_SORTORDER ON dbo.loc_org_hierarchy(sort_order)
GO

EXEC CREATE_PROPERTY_TABLE loc_org_hierarchy;
GO
PRINT '--- CREATING loc_pricing_hierarchy --- ';
CREATE TABLE dbo.loc_pricing_hierarchy(
organization_id INT NOT NULL,
level_code VARCHAR(30) DEFAULT ('*') NOT NULL,
level_value VARCHAR(60) DEFAULT ('*') NOT NULL,
parent_code VARCHAR(30),
parent_value VARCHAR(60),
description VARCHAR(254),
level_order INT,
sort_order INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_loc_pricing_hierarchy PRIMARY KEY CLUSTERED (organization_id, level_code, level_value))
GO
PRINT '--- CREATING XST_LOC_PRICEHIER_LVLORDER --- ';
CREATE INDEX XST_LOC_PRICEHIER_LVLORDER ON dbo.loc_pricing_hierarchy(level_order)
GO

PRINT '--- CREATING XST_LOC_PRICEHIER_PARENT --- ';
CREATE INDEX XST_LOC_PRICEHIER_PARENT ON dbo.loc_pricing_hierarchy(parent_code, parent_value)
GO

PRINT '--- CREATING XST_LOC_PRICEHIER_SORTORDER --- ';
CREATE INDEX XST_LOC_PRICEHIER_SORTORDER ON dbo.loc_pricing_hierarchy(sort_order)
GO

EXEC CREATE_PROPERTY_TABLE loc_pricing_hierarchy;
GO
PRINT '--- CREATING loc_rtl_loc --- ';
CREATE TABLE dbo.loc_rtl_loc(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
store_name VARCHAR(254),
address1 VARCHAR(254),
address2 VARCHAR(254),
address3 VARCHAR(254),
address4 VARCHAR(254),
city VARCHAR(254),
state VARCHAR(30),
district VARCHAR(30),
area VARCHAR(30),
postal_code VARCHAR(30),
country VARCHAR(2),
neighborhood VARCHAR(254),
county VARCHAR(254),
locale VARCHAR(30) NOT NULL,
currency_id VARCHAR(3),
latitude DECIMAL(17, 6),
longitude DECIMAL(17, 6),
telephone1 VARCHAR(32),
telephone2 VARCHAR(32),
telephone3 VARCHAR(32),
telephone4 VARCHAR(32),
description VARCHAR(254),
store_nbr VARCHAR(254),
apartment VARCHAR(30),
store_manager VARCHAR(254),
email_addr VARCHAR(254),
default_tax_percentage DECIMAL(8, 6),
location_type VARCHAR(60),
delivery_available_flag BIT DEFAULT (0) NOT NULL,
pickup_available_flag BIT DEFAULT (0) NOT NULL,
transfer_available_flag BIT DEFAULT (0) NOT NULL,
geo_code VARCHAR(20),
uez_flag BIT DEFAULT (0) NOT NULL,
alternate_store_nbr VARCHAR(254),
use_till_accountability_flag BIT DEFAULT (0) NOT NULL,
deposit_bank_name VARCHAR(254),
deposit_bank_account_number VARCHAR(30),
airport_code VARCHAR(3),
legal_entity_id VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_loc_rtl_loc PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id))
GO
EXEC CREATE_PROPERTY_TABLE loc_rtl_loc;
GO
PRINT '--- CREATING loc_state_journal --- ';
CREATE TABLE dbo.loc_state_journal(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
status_typcode VARCHAR(30) NOT NULL,
state_journal_id VARCHAR(60) NOT NULL,
time_stamp DATETIME NOT NULL,
date_value DATETIME,
string_value VARCHAR(30),
decimal_value DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_loc_state_journal PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, status_typcode, state_journal_id))
GO
PRINT '--- CREATING XST_LOC_STATEJOURNAL_TIME --- ';
CREATE INDEX XST_LOC_STATEJOURNAL_TIME ON dbo.loc_state_journal(time_stamp)
GO

EXEC CREATE_PROPERTY_TABLE loc_state_journal;
GO
PRINT '--- CREATING loc_temp_store_request --- ';
CREATE TABLE dbo.loc_temp_store_request(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
request_id BIGINT NOT NULL,
request_type VARCHAR(30),
store_created_flag BIT,
description VARCHAR(254),
start_date_str VARCHAR(8) NOT NULL,
end_date_str VARCHAR(8),
active_date_str VARCHAR(8),
assigned_server_host VARCHAR(254),
assigned_server_port INT,
status VARCHAR(30) NOT NULL,
approve_reject_notes VARCHAR(254),
use_store_tax_loc_flag BIT DEFAULT (1) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_loc_temp_store_request PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, request_id))
GO
EXEC CREATE_PROPERTY_TABLE loc_temp_store_request;
GO
PRINT '--- CREATING loc_wkstn --- ';
CREATE TABLE dbo.loc_wkstn(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_loc_wkstn PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id))
GO
EXEC CREATE_PROPERTY_TABLE loc_wkstn;
GO
PRINT '--- CREATING loc_wkstn_config_data --- ';
CREATE TABLE dbo.loc_wkstn_config_data(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id INT NOT NULL,
field_name VARCHAR(100) NOT NULL,
create_timestamp DATETIME NOT NULL,
field_value VARCHAR(1024),
link_column VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30))
GO
PRINT '--- CREATING IDX_LOC_WKSTN_CONFIG_DATA01 --- ';
CREATE INDEX IDX_LOC_WKSTN_CONFIG_DATA01 ON dbo.loc_wkstn_config_data(organization_id, rtl_loc_id, wkstn_id, field_name, create_timestamp)
GO

PRINT '--- CREATING log_sp_report --- ';
CREATE TABLE dbo.log_sp_report(
job_id INT NOT NULL,
loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
start_dt DATETIME,
end_dt DATETIME,
completed INT,
expected INT,
job_start DATETIME NOT NULL,
job_end DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_log_sp_report PRIMARY KEY CLUSTERED (job_id, loc_id, business_date, job_start))
GO
PRINT '--- CREATING prc_deal --- ';
CREATE TABLE dbo.prc_deal(
organization_id INT NOT NULL,
deal_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
description VARCHAR(128),
consumable BIT DEFAULT (0),
act_deferred BIT DEFAULT (0),
effective_date DATETIME,
end_date DATETIME,
start_time DATETIME,
end_time DATETIME,
generosity_cap DECIMAL(17, 6),
iteration_cap INT,
priority_nudge INT,
subtotal_min DECIMAL(17, 6),
subtotal_max DECIMAL(17, 6),
trans_deal_flag BIT DEFAULT (0) NOT NULL,
trwide_action VARCHAR(30),
trwide_amount DECIMAL(17, 6),
taxability_code VARCHAR(30),
promotion_id VARCHAR(60),
higher_nonaction_amt_flag BIT DEFAULT (0),
exclude_price_override_flag BIT DEFAULT (0),
exclude_discounted_flag BIT DEFAULT (0),
targeted_flag BIT DEFAULT (0),
week_sched_flag BIT,
sort_order INT DEFAULT (0) NOT NULL,
type VARCHAR(60),
group_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_prc_deal PRIMARY KEY CLUSTERED (organization_id, deal_id))
GO
PRINT '--- CREATING IDX_PRC_DEAL_ORGNODE --- ';
CREATE INDEX IDX_PRC_DEAL_ORGNODE ON dbo.prc_deal(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE prc_deal;
GO
PRINT '--- CREATING prc_deal_cust_groups --- ';
CREATE TABLE dbo.prc_deal_cust_groups(
organization_id INT NOT NULL,
deal_id VARCHAR(60) NOT NULL,
cust_group_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_prc_deal_cust_groups PRIMARY KEY CLUSTERED (organization_id, deal_id, cust_group_id))
GO
PRINT '--- CREATING IDX_PRC_DEAL_CUSTGROUPSORGNODE --- ';
CREATE INDEX IDX_PRC_DEAL_CUSTGROUPSORGNODE ON dbo.prc_deal_cust_groups(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE prc_deal_cust_groups;
GO
PRINT '--- CREATING prc_deal_document_xref --- ';
CREATE TABLE dbo.prc_deal_document_xref(
organization_id INT NOT NULL,
deal_id VARCHAR(60) NOT NULL,
series_id VARCHAR(60) NOT NULL,
document_type VARCHAR(30) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_prc_deal_document_xref PRIMARY KEY CLUSTERED (organization_id, deal_id, series_id, document_type))
GO
PRINT '--- CREATING IDX_PRC_DEAL_DOC_XREF_ORGNODE --- ';
CREATE INDEX IDX_PRC_DEAL_DOC_XREF_ORGNODE ON dbo.prc_deal_document_xref(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE prc_deal_document_xref;
GO
PRINT '--- CREATING prc_deal_field_test --- ';
CREATE TABLE dbo.prc_deal_field_test(
organization_id INT NOT NULL,
deal_id VARCHAR(60) NOT NULL,
item_ordinal INT NOT NULL,
item_condition_group INT NOT NULL,
item_condition_seq INT NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
item_field VARCHAR(60) NOT NULL,
match_rule VARCHAR(20) NOT NULL,
value1 VARCHAR(128) NOT NULL,
value2 VARCHAR(128),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_prc_deal_field_test PRIMARY KEY CLUSTERED (organization_id, deal_id, item_ordinal, item_condition_group, item_condition_seq))
GO
PRINT '--- CREATING IDX_PRC_DEAL_FIELD_TST_ORGNODE --- ';
CREATE INDEX IDX_PRC_DEAL_FIELD_TST_ORGNODE ON dbo.prc_deal_field_test(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE prc_deal_field_test;
GO
PRINT '--- CREATING prc_deal_item --- ';
CREATE TABLE dbo.prc_deal_item(
organization_id INT NOT NULL,
deal_id VARCHAR(60) NOT NULL,
item_ordinal INT NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
consumable BIT,
qty_min DECIMAL(17, 4),
qty_max DECIMAL(17, 4),
min_item_total DECIMAL(17, 6),
deal_action VARCHAR(30),
action_arg DECIMAL(17, 6),
action_arg_qty DECIMAL(17, 4),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_prc_deal_item PRIMARY KEY CLUSTERED (organization_id, deal_id, item_ordinal))
GO
PRINT '--- CREATING IDX_PRC_DEAL_ITEM_ORGNODE --- ';
CREATE INDEX IDX_PRC_DEAL_ITEM_ORGNODE ON dbo.prc_deal_item(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE prc_deal_item;
GO
PRINT '--- CREATING prc_deal_loc --- ';
CREATE TABLE dbo.prc_deal_loc(
organization_id INT NOT NULL,
deal_id VARCHAR(60) NOT NULL,
rtl_loc_id INT NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_prc_deal_loc PRIMARY KEY CLUSTERED (organization_id, deal_id, rtl_loc_id))
GO
EXEC CREATE_PROPERTY_TABLE prc_deal_loc;
GO
PRINT '--- CREATING prc_deal_trig --- ';
CREATE TABLE dbo.prc_deal_trig(
organization_id INT NOT NULL,
deal_id VARCHAR(60) NOT NULL,
deal_trigger VARCHAR(128) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_prc_deal_trig PRIMARY KEY CLUSTERED (organization_id, deal_id, deal_trigger))
GO
PRINT '--- CREATING IDX_PRC_DEAL_TRIG_ORGNODE --- ';
CREATE INDEX IDX_PRC_DEAL_TRIG_ORGNODE ON dbo.prc_deal_trig(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE prc_deal_trig;
GO
PRINT '--- CREATING prc_deal_week --- ';
CREATE TABLE dbo.prc_deal_week(
organization_id INT NOT NULL,
deal_id VARCHAR(60) NOT NULL,
day_code VARCHAR(3) NOT NULL,
start_time DATETIME NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
end_time DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_prc_deal_week PRIMARY KEY CLUSTERED (organization_id, deal_id, day_code, start_time))
GO
PRINT '--- CREATING IDX_PRC_DEAL_WEEK_ORGNODE --- ';
CREATE INDEX IDX_PRC_DEAL_WEEK_ORGNODE ON dbo.prc_deal_week(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE prc_deal_week;
GO
PRINT '--- CREATING rms_diff_group_detail --- ';
CREATE TABLE dbo.rms_diff_group_detail(
organization_id INT NOT NULL,
diff_group_id VARCHAR(10) NOT NULL,
diff_id VARCHAR(10) NOT NULL,
display_seq INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_rms_diff_group_detail PRIMARY KEY CLUSTERED (organization_id, diff_group_id, diff_id))
GO
PRINT '--- CREATING rms_diff_group_head --- ';
CREATE TABLE dbo.rms_diff_group_head(
organization_id INT NOT NULL,
diff_group_id VARCHAR(10) NOT NULL,
diff_type VARCHAR(6) NOT NULL,
diff_group_desc VARCHAR(120) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_rms_diff_group_head PRIMARY KEY CLUSTERED (organization_id, diff_group_id))
GO
PRINT '--- CREATING rms_diff_ids --- ';
CREATE TABLE dbo.rms_diff_ids(
organization_id INT NOT NULL,
diff_id VARCHAR(10) NOT NULL,
diff_desc VARCHAR(120),
diff_type VARCHAR(6) NOT NULL,
diff_type_desc VARCHAR(120),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_rms_diff_ids PRIMARY KEY CLUSTERED (organization_id, diff_id))
GO
PRINT '--- CREATING rms_related_item_head --- ';
CREATE TABLE dbo.rms_related_item_head(
organization_id INT NOT NULL,
relationship_id BIGINT NOT NULL,
item VARCHAR(25) NOT NULL,
location VARCHAR(10) NOT NULL,
relationship_name VARCHAR(255) NOT NULL,
relationship_type VARCHAR(6) NOT NULL,
mandatory_ind VARCHAR(1) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_rms_related_item_head PRIMARY KEY CLUSTERED (organization_id, relationship_id, location))
GO
PRINT '--- CREATING rpt_fifo --- ';
CREATE TABLE dbo.rpt_fifo(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
description VARCHAR(254),
style_id VARCHAR(60),
style_desc VARCHAR(254),
rtl_loc_id INT NOT NULL,
store_name VARCHAR(254),
unit_count DECIMAL(14, 4),
unit_cost DECIMAL(17, 6),
user_name VARCHAR(30) NOT NULL,
comment VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_rpt_fifo PRIMARY KEY CLUSTERED (organization_id, item_id, rtl_loc_id, user_name))
GO
PRINT '--- CREATING rpt_fifo_detail --- ';
CREATE TABLE dbo.rpt_fifo_detail(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
description VARCHAR(254),
style_id VARCHAR(60),
style_desc VARCHAR(254),
rtl_loc_id INT NOT NULL,
store_name VARCHAR(254),
invctl_doc_id VARCHAR(60) NOT NULL,
invctl_doc_line_nbr INT NOT NULL,
user_name VARCHAR(30) NOT NULL,
invctl_doc_create_date DATETIME,
unit_count DECIMAL(14, 4),
current_unit_count DECIMAL(14, 4),
unit_cost DECIMAL(17, 6),
unit_count_a DECIMAL(14, 4),
current_cost DECIMAL(17, 6),
comment VARCHAR(254),
pending_count DECIMAL(14, 4),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_rpt_fifo_detail PRIMARY KEY CLUSTERED (organization_id, item_id, rtl_loc_id, invctl_doc_id, invctl_doc_line_nbr, user_name))
GO
PRINT '--- CREATING rpt_flash_sales --- ';
CREATE TABLE dbo.rpt_flash_sales(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
line_enum VARCHAR(30) NOT NULL,
line_count DECIMAL(11, 4),
line_amt DECIMAL(17, 6),
foreign_amt DECIMAL(17, 6),
currency_id VARCHAR(3),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_rpt_flash_sales PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, line_enum))
GO
PRINT '--- CREATING rpt_flash_sales_goal --- ';
CREATE TABLE dbo.rpt_flash_sales_goal(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
sales_goal DECIMAL(17, 6),
sales_last_year DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_rpt_flash_sales_goal PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date))
GO
PRINT '--- CREATING rpt_item_price --- ';
CREATE TABLE dbo.rpt_item_price(
organization_id INT NOT NULL,
item_id VARCHAR(60) NOT NULL,
regular_price DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_rpt_item_price PRIMARY KEY CLUSTERED (organization_id, item_id))
GO
PRINT '--- CREATING rpt_merchlvl1_sales --- ';
CREATE TABLE dbo.rpt_merchlvl1_sales(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
merch_level_1 VARCHAR(60) NOT NULL,
line_count DECIMAL(11, 4),
line_amt DECIMAL(17, 6),
gross_amt DECIMAL(17, 6),
currency_id VARCHAR(3),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_rpt_merchlvl1_sales PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, merch_level_1))
GO
PRINT '--- CREATING rpt_organizer --- ';
CREATE TABLE dbo.rpt_organizer(
organization_id INT NOT NULL,
report_name VARCHAR(100) NOT NULL,
report_group VARCHAR(100) NOT NULL,
report_element VARCHAR(200) NOT NULL,
report_order INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_rpt_organizer PRIMARY KEY CLUSTERED (organization_id, report_name, report_group, report_element))
GO
EXEC CREATE_PROPERTY_TABLE rpt_organizer;
GO
PRINT '--- CREATING rpt_sale_line --- ';
CREATE TABLE dbo.rpt_sale_line(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
quantity DECIMAL(11, 4),
actual_quantity DECIMAL(11, 4),
gross_quantity DECIMAL(11, 4),
unit_price DECIMAL(17, 6),
net_amt DECIMAL(17, 6),
gross_amt DECIMAL(17, 6),
currency_id VARCHAR(3),
item_id VARCHAR(60),
item_desc VARCHAR(254),
merch_level_1 VARCHAR(60),
serial_nbr VARCHAR(60),
return_flag BIT DEFAULT (0),
override_amt DECIMAL(17, 6),
trans_timestamp DATETIME,
discount_amt DECIMAL(17, 6),
cust_party_id BIGINT,
last_name VARCHAR(254),
first_name VARCHAR(254),
trans_statcode VARCHAR(60),
sale_lineitm_typcode VARCHAR(60),
begin_time_int INT,
regular_base_price DECIMAL(17, 6),
exclude_from_net_sales_flag BIT DEFAULT (0),
trans_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_rpt_sale_line PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING IDX_RPT_SALE_LINE01 --- ';
CREATE INDEX IDX_RPT_SALE_LINE01 ON dbo.rpt_sale_line(trans_seq, business_date, rtl_loc_id, wkstn_id, organization_id, rtrans_lineitm_seq)
GO

PRINT '--- CREATING IDX_RPT_SALE_LINE02 --- ';
CREATE INDEX IDX_RPT_SALE_LINE02 ON dbo.rpt_sale_line(cust_party_id)
GO

PRINT '--- CREATING IDX_RPT_SALE_LINE03 --- ';
CREATE INDEX IDX_RPT_SALE_LINE03 ON dbo.rpt_sale_line(organization_id, trans_statcode, business_date, rtl_loc_id, wkstn_id, trans_seq, rtrans_lineitm_seq, quantity, net_amt)
GO

PRINT '--- CREATING IDX_RPT_SALE_LINE04 --- ';
CREATE INDEX IDX_RPT_SALE_LINE04 ON dbo.rpt_sale_line(trans_date)
GO

PRINT '--- CREATING rpt_sales_by_hour --- ';
CREATE TABLE dbo.rpt_sales_by_hour(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
hour INT NOT NULL,
business_date DATETIME NOT NULL,
trans_count INT,
qty DECIMAL(11, 4),
net_sales DECIMAL(17, 6),
gross_sales DECIMAL(17, 6),
currency_id VARCHAR(3),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_rpt_sales_by_hour PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, hour, business_date))
GO
PRINT '--- CREATING sch_emp_time_off --- ';
CREATE TABLE dbo.sch_emp_time_off(
organization_id INT NOT NULL,
employee_id VARCHAR(60) NOT NULL,
time_off_seq BIGINT NOT NULL,
start_datetime DATETIME,
end_datetime DATETIME,
reason_code VARCHAR(30),
void_flag BIT DEFAULT (0),
time_off_typcode VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sch_emp_time_off PRIMARY KEY CLUSTERED (organization_id, employee_id, time_off_seq))
GO
EXEC CREATE_PROPERTY_TABLE sch_emp_time_off;
GO
PRINT '--- CREATING sch_schedule --- ';
CREATE TABLE dbo.sch_schedule(
organization_id INT NOT NULL,
employee_id VARCHAR(60) NOT NULL,
business_date DATETIME NOT NULL,
schedule_seq BIGINT NOT NULL,
work_code VARCHAR(30),
start_time DATETIME,
end_time DATETIME,
void_flag BIT DEFAULT (0),
break_duration BIGINT,
schedule_duration BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sch_schedule PRIMARY KEY CLUSTERED (organization_id, employee_id, business_date, schedule_seq))
GO
EXEC CREATE_PROPERTY_TABLE sch_schedule;
GO
PRINT '--- CREATING sch_shift --- ';
CREATE TABLE dbo.sch_shift(
organization_id INT NOT NULL,
shift_id BIGINT NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
name VARCHAR(60),
description VARCHAR(254),
work_code VARCHAR(30),
start_time DATETIME,
end_time DATETIME,
void_flag BIT DEFAULT (0),
break_duration BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sch_shift PRIMARY KEY CLUSTERED (organization_id, shift_id))
GO
PRINT '--- CREATING IDX_SCH_SHIFT_ORGNODE --- ';
CREATE INDEX IDX_SCH_SHIFT_ORGNODE ON dbo.sch_shift(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE sch_shift;
GO
PRINT '--- CREATING sec_access_types --- ';
CREATE TABLE dbo.sec_access_types(
organization_id INT NOT NULL,
secured_object_id VARCHAR(30) NOT NULL,
access_typcode VARCHAR(30) NOT NULL,
group_membership VARCHAR(MAX) NOT NULL,
no_access_settings VARCHAR(30) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sec_access_types PRIMARY KEY CLUSTERED (organization_id, secured_object_id, access_typcode))
GO
EXEC CREATE_PROPERTY_TABLE sec_access_types;
GO
PRINT '--- CREATING sec_acl --- ';
CREATE TABLE dbo.sec_acl(
organization_id INT NOT NULL,
secured_object_id VARCHAR(30) NOT NULL,
authentication_req_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sec_acl PRIMARY KEY CLUSTERED (organization_id, secured_object_id))
GO
EXEC CREATE_PROPERTY_TABLE sec_acl;
GO
PRINT '--- CREATING sec_activity_log --- ';
CREATE TABLE dbo.sec_activity_log(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
business_date DATETIME,
trans_seq BIGINT,
activity_typcode VARCHAR(30) NOT NULL,
success_flag BIT,
employee_id VARCHAR(60),
overriding_employee_id VARCHAR(60),
privilege_type VARCHAR(255),
system_datetime DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30))
GO
PRINT '--- CREATING sec_group_roles --- ';
CREATE TABLE dbo.sec_group_roles(
organization_id INT NOT NULL,
group_id VARCHAR(60) NOT NULL,
role VARCHAR(50) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sec_group_roles PRIMARY KEY CLUSTERED (organization_id, group_id, role))
GO
PRINT '--- CREATING sec_groups --- ';
CREATE TABLE dbo.sec_groups(
organization_id INT NOT NULL,
group_id VARCHAR(60) NOT NULL,
description VARCHAR(254),
bitmap_position INT NOT NULL,
group_rank INT,
config_element VARCHAR(200) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sec_groups PRIMARY KEY CLUSTERED (organization_id, group_id))
GO
EXEC CREATE_PROPERTY_TABLE sec_groups;
GO
PRINT '--- CREATING sec_password --- ';
CREATE TABLE dbo.sec_password(
organization_id INT NOT NULL,
password_id INT NOT NULL,
password VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sec_password PRIMARY KEY CLUSTERED (organization_id, password_id))
GO
PRINT '--- CREATING sec_privilege --- ';
CREATE TABLE dbo.sec_privilege(
organization_id INT NOT NULL,
privilege_type VARCHAR(60) NOT NULL,
authentication_req BIT DEFAULT (0),
description VARCHAR(254),
overridable_flag BIT DEFAULT (0),
group_membership VARCHAR(MAX) NOT NULL,
second_prompt_settings VARCHAR(30),
second_prompt_req_diff_emp BIT DEFAULT (0) NOT NULL,
second_prompt_group_membership VARCHAR(MAX),
config_element VARCHAR(200) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sec_privilege PRIMARY KEY CLUSTERED (organization_id, privilege_type))
GO
EXEC CREATE_PROPERTY_TABLE sec_privilege;
GO
PRINT '--- CREATING sec_service_credentials --- ';
CREATE TABLE dbo.sec_service_credentials(
organization_id INT NOT NULL,
service_id VARCHAR(60) NOT NULL,
effective_date DATETIME NOT NULL,
expiration_date DATETIME,
user_name VARCHAR(1024) NOT NULL,
password VARCHAR(1024) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sec_service_credentials PRIMARY KEY CLUSTERED (organization_id, service_id, effective_date))
GO
EXEC CREATE_PROPERTY_TABLE sec_service_credentials;
GO
PRINT '--- CREATING sec_token_signing_data --- ';
CREATE TABLE dbo.sec_token_signing_data(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
effective_datetime DATETIME NOT NULL,
expiration_datetime DATETIME NOT NULL,
key_id VARCHAR(36) NOT NULL,
inactive_flag BIT,
key_algorithm VARCHAR(10) NOT NULL,
signature_algorithm VARCHAR(10) NOT NULL,
private_key_format VARCHAR(10) NOT NULL,
encrypted_private_key VARCHAR(MAX) NOT NULL,
public_key_format VARCHAR(10) NOT NULL,
public_key VARCHAR(MAX) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sec_token_signing_data PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, effective_datetime))
GO
PRINT '--- CREATING IDX_TOKEN_SIGNING_DATA_ID --- ';
CREATE INDEX IDX_TOKEN_SIGNING_DATA_ID ON dbo.sec_token_signing_data(organization_id, key_id)
GO

PRINT '--- CREATING sec_user_password --- ';
CREATE TABLE dbo.sec_user_password(
organization_id INT NOT NULL,
username VARCHAR(50) NOT NULL,
password_seq BIGINT NOT NULL,
password VARCHAR(254) NOT NULL,
effective_date DATETIME NOT NULL,
failed_attempts INT DEFAULT (0) NOT NULL,
locked_out_timestamp DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sec_user_password PRIMARY KEY CLUSTERED (organization_id, username, password_seq))
GO
EXEC CREATE_PROPERTY_TABLE sec_user_password;
GO
PRINT '--- CREATING sec_user_role --- ';
CREATE TABLE dbo.sec_user_role(
organization_id INT NOT NULL,
user_role_id INT NOT NULL,
username VARCHAR(50) NOT NULL,
role_code VARCHAR(50) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sec_user_role PRIMARY KEY CLUSTERED (organization_id, user_role_id))
GO
EXEC CREATE_PROPERTY_TABLE sec_user_role;
GO
PRINT '--- CREATING sls_sales_goal --- ';
CREATE TABLE dbo.sls_sales_goal(
organization_id INT NOT NULL,
sales_goal_id VARCHAR(60) NOT NULL,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
sales_goal_value DECIMAL(17, 6) NOT NULL,
effective_date DATETIME NOT NULL,
end_date DATETIME NOT NULL,
description VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_sls_sales_goal PRIMARY KEY CLUSTERED (organization_id, sales_goal_id))
GO
PRINT '--- CREATING IDX_SLS_SALES_GOAL_ORGNODE --- ';
CREATE INDEX IDX_SLS_SALES_GOAL_ORGNODE ON dbo.sls_sales_goal(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE sls_sales_goal;
GO
PRINT '--- CREATING tax_postal_code_mapping --- ';
CREATE TABLE dbo.tax_postal_code_mapping(
organization_id INT NOT NULL,
postal_code VARCHAR(100) NOT NULL,
city VARCHAR(254) NOT NULL,
tax_loc_id VARCHAR(60) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tax_postal_code_mapping PRIMARY KEY CLUSTERED (organization_id, postal_code, city, tax_loc_id))
GO
EXEC CREATE_PROPERTY_TABLE tax_postal_code_mapping;
GO
PRINT '--- CREATING tax_rtl_loc_tax_mapping --- ';
CREATE TABLE dbo.tax_rtl_loc_tax_mapping(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
tax_loc_id VARCHAR(60),
external_system VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tax_rtl_loc_tax_mapping PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id))
GO
EXEC CREATE_PROPERTY_TABLE tax_rtl_loc_tax_mapping;
GO
PRINT '--- CREATING tax_tax_authority --- ';
CREATE TABLE dbo.tax_tax_authority(
organization_id INT NOT NULL,
tax_authority_id VARCHAR(60) NOT NULL,
name VARCHAR(254),
rounding_code VARCHAR(30),
rounding_digits_quantity INT,
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
external_system VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tax_tax_authority PRIMARY KEY CLUSTERED (organization_id, tax_authority_id))
GO
PRINT '--- CREATING IDX_TAX_TAX_AUTHORITY_ORGNODE --- ';
CREATE INDEX IDX_TAX_TAX_AUTHORITY_ORGNODE ON dbo.tax_tax_authority(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE tax_tax_authority;
GO
PRINT '--- CREATING tax_tax_bracket --- ';
CREATE TABLE dbo.tax_tax_bracket(
organization_id INT NOT NULL,
tax_bracket_id VARCHAR(60) NOT NULL,
tax_bracket_seq_nbr INT NOT NULL,
org_code VARCHAR(30) DEFAULT ('*'),
org_value VARCHAR(60) DEFAULT ('*'),
tax_breakpoint DECIMAL(17, 6),
tax_amount DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tax_tax_bracket PRIMARY KEY CLUSTERED (organization_id, tax_bracket_id, tax_bracket_seq_nbr))
GO
PRINT '--- CREATING IDX_TAX_TAX_BRACKET_ORGNODE --- ';
CREATE INDEX IDX_TAX_TAX_BRACKET_ORGNODE ON dbo.tax_tax_bracket(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE tax_tax_bracket;
GO
PRINT '--- CREATING tax_tax_exemption --- ';
CREATE TABLE dbo.tax_tax_exemption(
organization_id INT NOT NULL,
tax_exemption_id VARCHAR(60) NOT NULL,
party_id BIGINT,
cert_nbr VARCHAR(30),
reascode VARCHAR(30),
cert_holder_name VARCHAR(254),
cert_country VARCHAR(2),
expiration_date DATETIME,
cert_state VARCHAR(30),
notes VARCHAR(254),
address_id VARCHAR(60),
phone_number VARCHAR(32),
region VARCHAR(30),
diplomatic_title VARCHAR(60),
cert_holder_first_name VARCHAR(60),
cert_holder_last_name VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tax_tax_exemption PRIMARY KEY CLUSTERED (organization_id, tax_exemption_id))
GO
PRINT '--- CREATING IDX_TAX_TAX_EXEMPTION01 --- ';
CREATE INDEX IDX_TAX_TAX_EXEMPTION01 ON dbo.tax_tax_exemption(party_id, organization_id)
GO

EXEC CREATE_PROPERTY_TABLE tax_tax_exemption;
GO
PRINT '--- CREATING tax_tax_group --- ';
CREATE TABLE dbo.tax_tax_group(
organization_id INT NOT NULL,
tax_group_id VARCHAR(60) NOT NULL,
name VARCHAR(254),
description VARCHAR(254),
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
external_system VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tax_tax_group PRIMARY KEY CLUSTERED (organization_id, tax_group_id))
GO
PRINT '--- CREATING IDX_TAX_TAX_GROUP_ORGNODE --- ';
CREATE INDEX IDX_TAX_TAX_GROUP_ORGNODE ON dbo.tax_tax_group(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE tax_tax_group;
GO
PRINT '--- CREATING tax_tax_group_mapping --- ';
CREATE TABLE dbo.tax_tax_group_mapping(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
tax_group_id VARCHAR(60) NOT NULL,
customer_group_id VARCHAR(60) NOT NULL,
priority INT,
new_tax_group_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tax_tax_group_mapping PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, tax_group_id, customer_group_id))
GO
EXEC CREATE_PROPERTY_TABLE tax_tax_group_mapping;
GO
PRINT '--- CREATING tax_tax_group_rule --- ';
CREATE TABLE dbo.tax_tax_group_rule(
organization_id INT NOT NULL,
tax_group_id VARCHAR(60) NOT NULL,
tax_loc_id VARCHAR(60) NOT NULL,
tax_rule_seq_nbr INT NOT NULL,
tax_authority_id VARCHAR(60),
name VARCHAR(254),
description VARCHAR(254),
compound_seq_nbr INT,
compound_flag BIT DEFAULT (0),
taxed_at_trans_level_flag BIT DEFAULT (0),
tax_typcode VARCHAR(30),
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
external_system VARCHAR(60),
fiscal_tax_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tax_tax_group_rule PRIMARY KEY CLUSTERED (organization_id, tax_group_id, tax_loc_id, tax_rule_seq_nbr))
GO
PRINT '--- CREATING IDX_TAX_TAX_GROUP_RULE_ORGNODE --- ';
CREATE INDEX IDX_TAX_TAX_GROUP_RULE_ORGNODE ON dbo.tax_tax_group_rule(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE tax_tax_group_rule;
GO
PRINT '--- CREATING tax_tax_loc --- ';
CREATE TABLE dbo.tax_tax_loc(
organization_id INT NOT NULL,
tax_loc_id VARCHAR(60) NOT NULL,
name VARCHAR(254),
description VARCHAR(254),
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
external_system VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tax_tax_loc PRIMARY KEY CLUSTERED (organization_id, tax_loc_id))
GO
PRINT '--- CREATING IDX_TAX_TAX_LOC_ORGNODE --- ';
CREATE INDEX IDX_TAX_TAX_LOC_ORGNODE ON dbo.tax_tax_loc(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE tax_tax_loc;
GO
PRINT '--- CREATING tax_tax_rate_rule --- ';
CREATE TABLE dbo.tax_tax_rate_rule(
organization_id INT NOT NULL,
tax_group_id VARCHAR(60) NOT NULL,
tax_loc_id VARCHAR(60) NOT NULL,
tax_rule_seq_nbr INT NOT NULL,
tax_rate_rule_seq INT NOT NULL,
tax_bracket_id VARCHAR(60),
tax_rate_min_taxable_amt DECIMAL(17, 6),
effective_datetime DATETIME,
expr_datetime DATETIME,
percentage DECIMAL(8, 6),
amt DECIMAL(17, 6),
daily_start_time DATETIME,
daily_end_time DATETIME,
tax_rate_max_taxable_amt DECIMAL(17, 6),
breakpoint_typcode VARCHAR(30),
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
external_system VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tax_tax_rate_rule PRIMARY KEY CLUSTERED (organization_id, tax_group_id, tax_loc_id, tax_rule_seq_nbr, tax_rate_rule_seq))
GO
PRINT '--- CREATING XST_TAX_RATERULE_EXPR --- ';
CREATE INDEX XST_TAX_RATERULE_EXPR ON dbo.tax_tax_rate_rule(organization_id, tax_group_id, tax_rule_seq_nbr, tax_loc_id, expr_datetime)
GO

PRINT '--- CREATING IDX_TAX_TAX_RATE_RULE_ORGNODE --- ';
CREATE INDEX IDX_TAX_TAX_RATE_RULE_ORGNODE ON dbo.tax_tax_rate_rule(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE tax_tax_rate_rule;
GO
PRINT '--- CREATING tax_tax_rate_rule_override --- ';
CREATE TABLE dbo.tax_tax_rate_rule_override(
organization_id INT NOT NULL,
tax_group_id VARCHAR(60) NOT NULL,
tax_loc_id VARCHAR(60) NOT NULL,
tax_rule_seq_nbr INT NOT NULL,
tax_rate_rule_seq INT NOT NULL,
expr_datetime DATETIME NOT NULL,
effective_datetime DATETIME,
tax_bracket_id VARCHAR(60),
percentage DECIMAL(8, 6),
amt DECIMAL(17, 6),
daily_start_time DATETIME,
daily_end_time DATETIME,
tax_rate_min_taxable_amt DECIMAL(17, 6),
tax_rate_max_taxable_amt DECIMAL(17, 6),
breakpoint_typcode VARCHAR(30),
org_code VARCHAR(30) DEFAULT ('*') NOT NULL,
org_value VARCHAR(60) DEFAULT ('*') NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tax_tax_rate_rule_override PRIMARY KEY CLUSTERED (organization_id, tax_group_id, tax_loc_id, tax_rule_seq_nbr, tax_rate_rule_seq, expr_datetime))
GO
PRINT '--- CREATING IDXTAXTAXRULEOVERRIDEORGNODE --- ';
CREATE INDEX IDXTAXTAXRULEOVERRIDEORGNODE ON dbo.tax_tax_rate_rule_override(org_code, org_value)
GO

EXEC CREATE_PROPERTY_TABLE tax_tax_rate_rule_override;
GO
PRINT '--- CREATING thr_payroll --- ';
CREATE TABLE dbo.thr_payroll(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
party_id BIGINT NOT NULL,
payroll_category VARCHAR(30) NOT NULL,
business_date DATETIME NOT NULL,
hours_count DECIMAL(11, 4),
posted_flag BIT DEFAULT (0),
posted_date DATETIME,
payroll_status VARCHAR(30),
reviewed_date DATETIME,
pay_code VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_thr_payroll PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, party_id, payroll_category, business_date))
GO
EXEC CREATE_PROPERTY_TABLE thr_payroll;
GO
PRINT '--- CREATING thr_payroll_category --- ';
CREATE TABLE dbo.thr_payroll_category(
organization_id INT NOT NULL,
payroll_category VARCHAR(30) NOT NULL,
description VARCHAR(254),
sort_order INT,
include_in_overtime_flag BIT DEFAULT (0),
working_category_flag BIT DEFAULT (0),
pay_code VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_thr_payroll_category PRIMARY KEY CLUSTERED (organization_id, payroll_category))
GO
EXEC CREATE_PROPERTY_TABLE thr_payroll_category;
GO
PRINT '--- CREATING thr_payroll_header --- ';
CREATE TABLE dbo.thr_payroll_header(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
party_id BIGINT NOT NULL,
week_ending_date DATETIME NOT NULL,
reviewed_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_thr_payroll_header PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, party_id, week_ending_date))
GO
EXEC CREATE_PROPERTY_TABLE thr_payroll_header;
GO
PRINT '--- CREATING thr_payroll_notes --- ';
CREATE TABLE dbo.thr_payroll_notes(
organization_id INT NOT NULL,
party_id BIGINT NOT NULL,
week_ending_date DATETIME NOT NULL,
note_seq BIGINT NOT NULL,
note_text VARCHAR(MAX),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_thr_payroll_notes PRIMARY KEY CLUSTERED (organization_id, party_id, week_ending_date, note_seq))
GO
EXEC CREATE_PROPERTY_TABLE thr_payroll_notes;
GO
PRINT '--- CREATING thr_timecard_entry --- ';
CREATE TABLE dbo.thr_timecard_entry(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
party_id BIGINT NOT NULL,
timecard_entry_id INT NOT NULL,
clock_in_timestamp DATETIME,
clock_out_timestamp DATETIME,
work_code VARCHAR(30),
open_record_flag BIT DEFAULT (0),
entry_type_enum VARCHAR(30),
delete_flag BIT DEFAULT (0),
duration BIGINT,
payroll_update_required BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_thr_timecard_entry PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, party_id, timecard_entry_id))
GO
EXEC CREATE_PROPERTY_TABLE thr_timecard_entry;
GO
PRINT '--- CREATING thr_timecard_entry_comment --- ';
CREATE TABLE dbo.thr_timecard_entry_comment(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
party_id BIGINT NOT NULL,
week_ending_date DATETIME NOT NULL,
comment_seq BIGINT NOT NULL,
comment_text VARCHAR(MAX),
comment_timestamp DATETIME,
creator_id VARCHAR(254),
business_date DATETIME,
timecard_entry_id INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_thr_timecard_entry_comment PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, party_id, week_ending_date, comment_seq))
GO
EXEC CREATE_PROPERTY_TABLE thr_timecard_entry_comment;
GO
PRINT '--- CREATING thr_timecard_journal --- ';
CREATE TABLE dbo.thr_timecard_journal(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT DEFAULT (0) NOT NULL,
party_id BIGINT NOT NULL,
timecard_entry_id INT NOT NULL,
timecard_entry_seq BIGINT NOT NULL,
clock_in_timestamp DATETIME,
clock_out_timestamp DATETIME,
work_code VARCHAR(30),
entry_type_enum VARCHAR(30),
delete_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_thr_timecard_journal PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, party_id, timecard_entry_id, timecard_entry_seq))
GO
EXEC CREATE_PROPERTY_TABLE thr_timecard_journal;
GO
PRINT '--- CREATING thr_timeclk_trans --- ';
CREATE TABLE dbo.thr_timeclk_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
timecard_entry_wkstn_id BIGINT,
work_code VARCHAR(30),
timeclk_entry_code VARCHAR(30),
party_id BIGINT,
timecard_entry_id INT,
timecard_entry_seq BIGINT,
timecard_entry_business_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_thr_timeclk_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING tnd_exchange_rate --- ';
CREATE TABLE dbo.tnd_exchange_rate(
organization_id INT NOT NULL,
base_currency VARCHAR(3) NOT NULL,
target_currency VARCHAR(3) NOT NULL,
level_code VARCHAR(30) DEFAULT ('*') NOT NULL,
level_value VARCHAR(60) DEFAULT ('*') NOT NULL,
rate DECIMAL(17, 6),
print_as_inverted BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tnd_exchange_rate PRIMARY KEY CLUSTERED (organization_id, base_currency, target_currency, level_code, level_value))
GO
EXEC CREATE_PROPERTY_TABLE tnd_exchange_rate;
GO
PRINT '--- CREATING tnd_pbl_adyen_result --- ';
CREATE TABLE dbo.tnd_pbl_adyen_result(
organization_id INT NOT NULL,
psp_reference VARCHAR(30) NOT NULL,
is_live_auth BIT DEFAULT (0),
event_code VARCHAR(60),
event_date DATETIME,
merchant_account_code VARCHAR(254),
merchant_reference VARCHAR(60),
original_psp_reference VARCHAR(30),
payment_method VARCHAR(60),
payment_amount DECIMAL(17, 6),
currency_id VARCHAR(3),
success BIT,
reason_code VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tnd_pbl_adyen_result PRIMARY KEY CLUSTERED (organization_id, psp_reference))
GO
EXEC CREATE_PROPERTY_TABLE tnd_pbl_adyen_result;
GO
PRINT '--- CREATING tnd_tndr --- ';
CREATE TABLE dbo.tnd_tndr(
organization_id INT NOT NULL,
tndr_id VARCHAR(60) NOT NULL,
tndr_typcode VARCHAR(30),
currency_id VARCHAR(3) NOT NULL,
description VARCHAR(254),
display_order INT,
flash_sales_display_order INT,
disabled_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tnd_tndr PRIMARY KEY CLUSTERED (organization_id, tndr_id))
GO
EXEC CREATE_PROPERTY_TABLE tnd_tndr;
GO
PRINT '--- CREATING tnd_tndr_availability --- ';
CREATE TABLE dbo.tnd_tndr_availability(
organization_id INT NOT NULL,
tndr_id VARCHAR(60) NOT NULL,
availability_code VARCHAR(30) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tnd_tndr_availability PRIMARY KEY CLUSTERED (organization_id, tndr_id, availability_code))
GO
EXEC CREATE_PROPERTY_TABLE tnd_tndr_availability;
GO
PRINT '--- CREATING tnd_tndr_denomination --- ';
CREATE TABLE dbo.tnd_tndr_denomination(
organization_id INT NOT NULL,
tndr_id VARCHAR(60) NOT NULL,
denomination_id VARCHAR(60) NOT NULL,
description VARCHAR(254),
value DECIMAL(17, 6),
sort_order INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tnd_tndr_denomination PRIMARY KEY CLUSTERED (organization_id, tndr_id, denomination_id))
GO
EXEC CREATE_PROPERTY_TABLE tnd_tndr_denomination;
GO
PRINT '--- CREATING tnd_tndr_options --- ';
CREATE TABLE dbo.tnd_tndr_options(
organization_id INT NOT NULL,
tndr_id VARCHAR(60) NOT NULL,
config_element VARCHAR(200) DEFAULT ('*') NOT NULL,
auth_mthd_code VARCHAR(30),
serial_id_nbr_req_flag BIT DEFAULT (0),
auth_req_flag BIT DEFAULT (0),
auth_expr_date_req_flag BIT DEFAULT (0),
pin_req_flag BIT DEFAULT (0),
cust_sig_req_flag BIT DEFAULT (0),
endorsement_req_flag BIT DEFAULT (0),
open_cash_drawer_req_flag BIT DEFAULT (0),
unit_count_req_code VARCHAR(30),
mag_swipe_reader_req_flag BIT DEFAULT (0),
dflt_to_amt_due_flag BIT DEFAULT (0),
min_denomination_amt DECIMAL(17, 6),
reporting_group VARCHAR(30),
effective_date DATETIME,
expr_date DATETIME,
min_days_for_return INT,
max_days_for_return INT,
cust_id_req_code VARCHAR(30),
cust_association_flag BIT DEFAULT (0),
populate_system_count_flag BIT DEFAULT (0),
include_in_type_count_flag BIT DEFAULT (0),
suggested_deposit_threshold DECIMAL(17, 6),
suggest_deposit_flag BIT DEFAULT (0),
change_tndr_id VARCHAR(60),
cash_change_limit DECIMAL(17, 6),
over_tender_overridable_flag BIT DEFAULT (0),
non_voidable_flag BIT DEFAULT (0),
disallow_split_tndr_flag BIT DEFAULT (0),
close_count_disc_threshold DECIMAL(17, 6),
cid_msr_req_flag BIT DEFAULT (0),
cid_keyed_req_flag BIT DEFAULT (0),
postal_code_req_flag BIT DEFAULT (0),
post_void_open_drawer_flag BIT DEFAULT (0),
change_allowed_when_foreign BIT DEFAULT (0),
fiscal_tndr_id VARCHAR(60),
rounding_mode VARCHAR(254),
assign_cash_drawer_req_flag BIT DEFAULT (0),
post_void_assign_drawer_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tnd_tndr_options PRIMARY KEY CLUSTERED (organization_id, tndr_id, config_element))
GO
EXEC CREATE_PROPERTY_TABLE tnd_tndr_options;
GO
PRINT '--- CREATING tnd_tndr_typcode --- ';
CREATE TABLE dbo.tnd_tndr_typcode(
organization_id INT NOT NULL,
tndr_typcode VARCHAR(30) NOT NULL,
description VARCHAR(254),
sort_order INT,
unit_count_req_code VARCHAR(30),
close_count_disc_threshold DECIMAL(17, 6),
hidden_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tnd_tndr_typcode PRIMARY KEY CLUSTERED (organization_id, tndr_typcode))
GO
EXEC CREATE_PROPERTY_TABLE tnd_tndr_typcode;
GO
PRINT '--- CREATING tnd_tndr_user_settings --- ';
CREATE TABLE dbo.tnd_tndr_user_settings(
organization_id INT NOT NULL,
tndr_id VARCHAR(60) NOT NULL,
group_id VARCHAR(60) NOT NULL,
usage_code VARCHAR(30) NOT NULL,
entry_mthd_code VARCHAR(60) DEFAULT ('DEFAULT') NOT NULL,
config_element VARCHAR(200) DEFAULT ('*') NOT NULL,
online_floor_approval_amt DECIMAL(17, 6),
online_ceiling_approval_amt DECIMAL(17, 6),
over_tndr_limit DECIMAL(17, 6),
offline_floor_approval_amt DECIMAL(17, 6),
offline_ceiling_approval_amt DECIMAL(17, 6),
min_accept_amt DECIMAL(17, 6),
max_accept_amt DECIMAL(17, 6),
max_refund_with_receipt DECIMAL(17, 6),
max_refund_wo_receipt DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tnd_tndr_user_settings PRIMARY KEY CLUSTERED (organization_id, tndr_id, group_id, usage_code, entry_mthd_code, config_element))
GO
EXEC CREATE_PROPERTY_TABLE tnd_tndr_user_settings;
GO
PRINT '--- CREATING trl_ar_sale_lineitm --- ';
CREATE TABLE dbo.trl_ar_sale_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
acct_nbr VARCHAR(60),
auth_mthd_code VARCHAR(30),
adjudication_code VARCHAR(30),
entry_mthd_code VARCHAR(30),
auth_code VARCHAR(30),
activity_code VARCHAR(30),
reference_nbr VARCHAR(254),
acct_user_id VARCHAR(30),
acct_user_name VARCHAR(254),
orig_transmission_date_time VARCHAR(20),
orig_stan VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_ar_sale_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING trl_commission_mod --- ';
CREATE TABLE dbo.trl_commission_mod(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
commission_mod_seq_nbr INT NOT NULL,
typcode VARCHAR(30),
amt DECIMAL(17, 6),
percentage DECIMAL(6, 4),
percentage_of_item DECIMAL(6, 4),
employee_party_id BIGINT,
unverifiable_emp_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_commission_mod PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, commission_mod_seq_nbr))
GO
EXEC CREATE_PROPERTY_TABLE trl_commission_mod;
GO
PRINT '--- CREATING trl_correction_mod --- ';
CREATE TABLE dbo.trl_correction_mod(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
original_rtl_loc_id INT,
original_wkstn_id BIGINT,
original_business_date DATETIME,
original_trans_seq BIGINT,
original_rtrans_lineitm_seq INT,
reascode VARCHAR(30),
notes VARCHAR(254),
original_base_unit_amt DECIMAL(17, 6),
original_base_extended_amt DECIMAL(17, 6),
original_unit_amt DECIMAL(17, 6),
original_extended_amt DECIMAL(17, 6),
original_tax_amt DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_correction_mod PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE trl_correction_mod;
GO
PRINT '--- CREATING trl_coupon_lineitm --- ';
CREATE TABLE dbo.trl_coupon_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
coupon_id VARCHAR(254),
typcode VARCHAR(30),
serialized_flag BIT DEFAULT (0),
expr_date DATETIME,
entry_mthd_code VARCHAR(30),
manufacturer_id VARCHAR(254),
value_code VARCHAR(30),
manufacturer_family_code VARCHAR(254),
amt_entered DECIMAL(17, 6),
authorized_flag BIT DEFAULT (0),
redemption_trans_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_coupon_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING trl_cust_item_acct_mod --- ';
CREATE TABLE dbo.trl_cust_item_acct_mod(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
cust_acct_id VARCHAR(60),
cust_acct_code VARCHAR(30),
item_acct_extended_price DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_cust_item_acct_mod PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE trl_cust_item_acct_mod;
GO
PRINT '--- CREATING trl_deal_lineitm --- ';
CREATE TABLE dbo.trl_deal_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
amt DECIMAL(17, 6),
deal_id VARCHAR(60) NOT NULL,
discount_reascode VARCHAR(30) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_deal_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING trl_dimension_mod --- ';
CREATE TABLE dbo.trl_dimension_mod(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
dimension_code VARCHAR(30) NOT NULL,
value VARCHAR(256),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_dimension_mod PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, dimension_code))
GO
EXEC CREATE_PROPERTY_TABLE trl_dimension_mod;
GO
PRINT '--- CREATING trl_discount_lineitm --- ';
CREATE TABLE dbo.trl_discount_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
discount_code VARCHAR(60),
percentage DECIMAL(6, 4),
amt DECIMAL(17, 6),
serial_number VARCHAR(254),
new_price_quantity DECIMAL(11, 4),
new_price DECIMAL(17, 6),
taxability_code VARCHAR(30),
award_trans_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_discount_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING trl_escrow_trans --- ';
CREATE TABLE dbo.trl_escrow_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
escrow_amt DECIMAL(17, 6),
cust_party_id BIGINT,
cust_acct_id VARCHAR(60),
activity_seq_nbr BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_escrow_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING trl_invctl_document_mod --- ';
CREATE TABLE dbo.trl_invctl_document_mod(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
invctl_document_mod_seq INT NOT NULL,
invctl_document_id VARCHAR(60),
document_typcode VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_invctl_document_mod PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, invctl_document_mod_seq))
GO
EXEC CREATE_PROPERTY_TABLE trl_invctl_document_mod;
GO
PRINT '--- CREATING trl_inventory_loc_mod --- ';
CREATE TABLE dbo.trl_inventory_loc_mod(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
mod_seq INT NOT NULL,
serial_nbr VARCHAR(254),
source_location_id VARCHAR(60),
source_bucket_id VARCHAR(60),
dest_location_id VARCHAR(60),
dest_bucket_id VARCHAR(60),
quantity DECIMAL(11, 4),
action_code VARCHAR(30),
void_flag BIT DEFAULT (0),
item_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_inventory_loc_mod PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, mod_seq))
GO
EXEC CREATE_PROPERTY_TABLE trl_inventory_loc_mod;
GO
PRINT '--- CREATING trl_kit_component_mod --- ';
CREATE TABLE dbo.trl_kit_component_mod(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
component_item_id VARCHAR(60) NOT NULL,
seq_nbr INT DEFAULT (1) NOT NULL,
component_item_desc VARCHAR(254),
display_order INT,
quantity INT,
kit_item_id VARCHAR(60),
serial_nbr VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_kit_component_mod PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, component_item_id, seq_nbr))
GO
EXEC CREATE_PROPERTY_TABLE trl_kit_component_mod;
GO
PRINT '--- CREATING trl_lineitm_assoc_mod --- ';
CREATE TABLE dbo.trl_lineitm_assoc_mod(
organization_id INT NOT NULL,
parent_rtrans_lineitm_seq INT NOT NULL,
parent_rtl_loc_id INT NOT NULL,
parent_business_date DATETIME NOT NULL,
parent_wkstn_id BIGINT NOT NULL,
parent_trans_seq BIGINT NOT NULL,
lineitm_assoc_mod_seq INT NOT NULL,
lineitm_assoc_typcode VARCHAR(30),
child_rtrans_lineitm_seq INT,
child_rtl_loc_id INT,
child_wkstn_id BIGINT,
child_business_date DATETIME,
child_trans_seq BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_lineitm_assoc_mod PRIMARY KEY CLUSTERED (organization_id, parent_rtrans_lineitm_seq, parent_rtl_loc_id, parent_business_date, parent_wkstn_id, parent_trans_seq, lineitm_assoc_mod_seq))
GO
EXEC CREATE_PROPERTY_TABLE trl_lineitm_assoc_mod;
GO
PRINT '--- CREATING trl_lineitm_assoc_typcode --- ';
CREATE TABLE dbo.trl_lineitm_assoc_typcode(
organization_id INT NOT NULL,
lineitm_assoc_typcode VARCHAR(30) NOT NULL,
description VARCHAR(254),
sort_order INT,
parent_restrict_quantity_flag BIT DEFAULT (0),
child_restrict_quantity_flag BIT DEFAULT (0),
parent_restrict_price_flag BIT DEFAULT (0),
child_restrict_price_flag BIT DEFAULT (0),
parent_restrict_delete_flag BIT DEFAULT (0),
child_restrict_delete_flag BIT DEFAULT (0),
cascade_delete_flag BIT DEFAULT (0),
cascade_quantity_flag BIT DEFAULT (0) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_lineitm_assoc_typcode PRIMARY KEY CLUSTERED (organization_id, lineitm_assoc_typcode))
GO
EXEC CREATE_PROPERTY_TABLE trl_lineitm_assoc_typcode;
GO
PRINT '--- CREATING trl_lineitm_notes --- ';
CREATE TABLE dbo.trl_lineitm_notes(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
note_seq INT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
note_datetime DATETIME,
posted_flag BIT DEFAULT (0),
note VARCHAR(MAX),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_lineitm_notes PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, note_seq, trans_seq, rtrans_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE trl_lineitm_notes;
GO
PRINT '--- CREATING trl_returned_item_count --- ';
CREATE TABLE dbo.trl_returned_item_count(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
returned_count DECIMAL(11, 4),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_returned_item_count PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE trl_returned_item_count;
GO
PRINT '--- CREATING trl_returned_item_journal --- ';
CREATE TABLE dbo.trl_returned_item_journal(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
journal_seq BIGINT NOT NULL,
returned_count DECIMAL(11, 4),
rtn_rtl_loc_id INT,
rtn_wkstn_id BIGINT,
rtn_business_date DATETIME,
rtn_trans_seq BIGINT,
rtn_rtrans_lineitm_seq INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_returned_item_journal PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, journal_seq))
GO
EXEC CREATE_PROPERTY_TABLE trl_returned_item_journal;
GO
PRINT '--- CREATING trl_rtl_price_mod --- ';
CREATE TABLE dbo.trl_rtl_price_mod(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
rtl_price_mod_seq_nbr INT NOT NULL,
trans_seq BIGINT NOT NULL,
promotion_id VARCHAR(60),
percentage DECIMAL(6, 4),
amt DECIMAL(17, 6),
price_change_amt DECIMAL(17, 6),
notes VARCHAR(254),
rtl_price_mod_reascode VARCHAR(30),
void_flag BIT DEFAULT (0),
disc_rtrans_lineitm_seq INT,
disc_rtl_loc_id INT,
disc_wkstn_id BIGINT,
disc_business_date DATETIME,
disc_trans_seq BIGINT,
discount_code VARCHAR(60),
price_change_reascode VARCHAR(30),
deal_id VARCHAR(60),
deal_amt DECIMAL(17, 6),
serial_number VARCHAR(254),
discount_group_id INT,
description VARCHAR(254),
discount_reascode VARCHAR(30),
extended_amt DECIMAL(17, 6),
taxability_code VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_rtl_price_mod PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, rtrans_lineitm_seq, rtl_price_mod_seq_nbr, trans_seq))
GO
PRINT '--- CREATING IDX_TRL_RTL_PRICE_MOD01 --- ';
CREATE INDEX IDX_TRL_RTL_PRICE_MOD01 ON dbo.trl_rtl_price_mod(trans_seq, business_date, rtl_loc_id, wkstn_id, organization_id, rtrans_lineitm_seq, rtl_price_mod_seq_nbr)
GO

EXEC CREATE_PROPERTY_TABLE trl_rtl_price_mod;
GO
PRINT '--- CREATING trl_rtrans --- ';
CREATE TABLE dbo.trl_rtrans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
cust_party_id BIGINT,
loyalty_card_number VARCHAR(60),
tax_exemption_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_rtrans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING IDX_TRL_RTRANS01 --- ';
CREATE INDEX IDX_TRL_RTRANS01 ON dbo.trl_rtrans(trans_seq, business_date, rtl_loc_id, wkstn_id, organization_id)
GO

PRINT '--- CREATING IDX_TRL_RTRANS02 --- ';
CREATE INDEX IDX_TRL_RTRANS02 ON dbo.trl_rtrans(cust_party_id)
GO

PRINT '--- CREATING trl_rtrans_flight_info --- ';
CREATE TABLE dbo.trl_rtrans_flight_info(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
flight_number VARCHAR(30) NOT NULL,
destination_airport VARCHAR(3),
destination_country VARCHAR(2),
destination_zone VARCHAR(30),
destination_airport_name VARCHAR(254),
origin_airport VARCHAR(3),
tax_calculation_mode VARCHAR(30),
first_flight_number VARCHAR(30),
first_destination_airport VARCHAR(3),
first_origin_airport VARCHAR(3),
first_flight_seat_number VARCHAR(4),
first_flight_scheduled_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_rtrans_flight_info PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
EXEC CREATE_PROPERTY_TABLE trl_rtrans_flight_info;
GO
PRINT '--- CREATING trl_rtrans_lineitm --- ';
CREATE TABLE dbo.trl_rtrans_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
begin_date_timestamp DATETIME,
end_date_timestamp DATETIME,
notes VARCHAR(254),
rtrans_lineitm_typcode VARCHAR(30),
rtrans_lineitm_statcode VARCHAR(30),
void_flag BIT DEFAULT (0),
dtv_class_name VARCHAR(254),
void_lineitm_reascode VARCHAR(30),
generic_storage_flag BIT DEFAULT (0),
tlog_lineitm_seq INT,
currency_id VARCHAR(3),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_rtrans_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING IDX_TRL_RTRANS_LINEITM01 --- ';
CREATE INDEX IDX_TRL_RTRANS_LINEITM01 ON dbo.trl_rtrans_lineitm(trans_seq, business_date, rtl_loc_id, wkstn_id, organization_id, rtrans_lineitm_seq)
GO

PRINT '--- CREATING IDX_TRL_RTRANS_LINEITM02 --- ';
CREATE INDEX IDX_TRL_RTRANS_LINEITM02 ON dbo.trl_rtrans_lineitm(organization_id, void_flag, business_date)
GO

PRINT '--- CREATING IDX_TRL_RTRANS_LINEITM03 --- ';
CREATE INDEX IDX_TRL_RTRANS_LINEITM03 ON dbo.trl_rtrans_lineitm(organization_id, rtl_loc_id, wkstn_id, trans_seq, void_flag)
GO

EXEC CREATE_PROPERTY_TABLE trl_rtrans_lineitm;
GO
PRINT '--- CREATING trl_rtrans_serial_exchange --- ';
CREATE TABLE dbo.trl_rtrans_serial_exchange(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
item_id VARCHAR(60),
orig_serial_nbr VARCHAR(60),
new_serial_nbr VARCHAR(60),
exchange_comment VARCHAR(254),
exchange_reason_code VARCHAR(30),
orig_lineitm_seq INT,
orig_rtl_loc_id INT,
orig_wkstn_id BIGINT,
orig_business_date DATETIME,
orig_trans_seq BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_rtrans_serial_exchange PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE trl_rtrans_serial_exchange;
GO
PRINT '--- CREATING trl_sale_lineitm --- ';
CREATE TABLE dbo.trl_sale_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
merch_level_1 VARCHAR(60),
item_id VARCHAR(60),
quantity DECIMAL(11, 4),
gross_quantity DECIMAL(11, 4),
net_quantity DECIMAL(11, 4),
unit_price DECIMAL(17, 6),
extended_amt DECIMAL(17, 6),
vat_amt DECIMAL(17, 6),
return_flag BIT DEFAULT (0),
item_id_entry_mthd_code VARCHAR(30),
price_entry_mthd_code VARCHAR(30),
price_derivtn_mthd_code VARCHAR(30),
price_property_code VARCHAR(60),
net_amt DECIMAL(17, 6),
gross_amt DECIMAL(17, 6),
serial_nbr VARCHAR(60),
scanned_item_id VARCHAR(60),
sale_lineitm_typcode VARCHAR(30),
tax_group_id VARCHAR(60),
inventory_action_code VARCHAR(30),
original_rtrans_lineitm_seq INT,
original_rtl_loc_id INT,
original_wkstn_id BIGINT,
original_business_date DATETIME,
original_trans_seq BIGINT,
return_comment VARCHAR(254),
return_reascode VARCHAR(30),
return_typcode VARCHAR(30),
rcpt_count INT,
base_unit_price DECIMAL(17, 6),
base_extended_price DECIMAL(17, 6),
force_zero_extended_amt_flag BIT DEFAULT (0),
entered_description VARCHAR(254),
rpt_base_unit_price DECIMAL(17, 6),
food_stamps_applied_amount DECIMAL(17, 6),
vendor_id VARCHAR(60),
regular_base_price DECIMAL(17, 6),
shipping_weight DECIMAL(12, 3),
unit_cost DECIMAL(17, 6),
attached_item_flag BIT,
initial_quantity DECIMAL(11, 4),
not_returnable_flag BIT DEFAULT (0),
exclude_from_net_sales_flag BIT DEFAULT (0),
measure_req_flag BIT DEFAULT (0),
weight_entry_mthd_code VARCHAR(30),
tare_value DECIMAL(11, 4),
tare_type VARCHAR(30),
tare_unit_of_measure_code VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_sale_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING IDX_TRL_SALE_LINEITM01 --- ';
CREATE INDEX IDX_TRL_SALE_LINEITM01 ON dbo.trl_sale_lineitm(trans_seq, business_date, rtl_loc_id, wkstn_id, organization_id, rtrans_lineitm_seq)
GO

PRINT '--- CREATING IDX_TRL_SALE_LINEITEM02 --- ';
CREATE INDEX IDX_TRL_SALE_LINEITEM02 ON dbo.trl_sale_lineitm(organization_id, business_date, sale_lineitm_typcode)
GO

PRINT '--- CREATING trl_sale_tax_lineitm --- ';
CREATE TABLE dbo.trl_sale_tax_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
sale_tax_lineitm_seq INT NOT NULL,
taxable_amt DECIMAL(17, 6),
tax_amt DECIMAL(17, 6),
tax_exempt_amt DECIMAL(17, 6),
tax_loc_id VARCHAR(60),
tax_group_id VARCHAR(60),
tax_rule_seq_nbr INT,
tax_exemption_id VARCHAR(60),
tax_override_amt DECIMAL(17, 6),
tax_override_percentage DECIMAL(10, 8),
tax_override_bracket_id VARCHAR(60),
tax_override_flag BIT DEFAULT (0),
tax_override_reascode VARCHAR(30),
void_flag BIT DEFAULT (0),
raw_tax_percentage DECIMAL(10, 8),
raw_tax_amount DECIMAL(17, 6),
exempt_tax_amount DECIMAL(17, 6),
tax_percentage DECIMAL(10, 8),
authority_id VARCHAR(60),
authority_name VARCHAR(254),
authority_type_code VARCHAR(60),
tax_override_comment VARCHAR(255),
orig_taxable_amount DECIMAL(17, 6),
orig_tax_group_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_sale_tax_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, sale_tax_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE trl_sale_tax_lineitm;
GO
PRINT '--- CREATING trl_tax_lineitm --- ';
CREATE TABLE dbo.trl_tax_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
tax_rule_seq_nbr INT,
tax_group_id VARCHAR(60),
taxable_amt DECIMAL(17, 6),
tax_amt DECIMAL(17, 6),
tax_override_flag BIT DEFAULT (0),
tax_override_amt DECIMAL(17, 6),
tax_override_percentage DECIMAL(10, 8),
tax_override_reascode VARCHAR(30),
tax_loc_id VARCHAR(60) NOT NULL,
raw_tax_percentage DECIMAL(8, 6),
raw_tax_amount DECIMAL(17, 6),
tax_percentage DECIMAL(12, 6),
authority_id VARCHAR(60),
authority_name VARCHAR(254),
authority_type_code VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_tax_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING trl_voucher_discount_lineitm --- ';
CREATE TABLE dbo.trl_voucher_discount_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
voucher_typcode VARCHAR(30),
auth_mthd_code VARCHAR(30),
adjudication_code VARCHAR(30),
entry_mthd_code VARCHAR(30),
auth_code VARCHAR(30),
activity_code VARCHAR(30),
reference_nbr VARCHAR(254),
effective_date DATETIME,
expr_date DATETIME,
face_value_amt DECIMAL(17, 6),
issue_datetime DATETIME,
issue_typcode VARCHAR(30),
unspent_balance_amt DECIMAL(17, 6),
voucher_status_code VARCHAR(30),
trace_number VARCHAR(60),
orig_transmission_date_time VARCHAR(20),
orig_stan VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_voucher_discount_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING trl_voucher_sale_lineitm --- ';
CREATE TABLE dbo.trl_voucher_sale_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
voucher_typcode VARCHAR(30),
auth_mthd_code VARCHAR(30),
adjudication_code VARCHAR(100),
entry_mthd_code VARCHAR(30),
auth_code VARCHAR(30),
activity_code VARCHAR(30),
reference_nbr VARCHAR(254),
effective_date DATETIME,
expr_date DATETIME,
face_value_amt DECIMAL(17, 6),
issue_datetime DATETIME,
issue_typcode VARCHAR(30),
unspent_balance_amt DECIMAL(17, 6),
voucher_status_code VARCHAR(30),
trace_number VARCHAR(60),
orig_local_date_time VARCHAR(20),
orig_transmission_date_time VARCHAR(20),
orig_stan VARCHAR(60),
merchant_cat_code VARCHAR(4),
card_type VARCHAR(20),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_voucher_sale_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING trl_warranty_modifier --- ';
CREATE TABLE dbo.trl_warranty_modifier(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
warranty_modifier_seq INT NOT NULL,
warranty_nbr VARCHAR(30),
warranty_typcode VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trl_warranty_modifier PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, warranty_modifier_seq))
GO
EXEC CREATE_PROPERTY_TABLE trl_warranty_modifier;
GO
PRINT '--- CREATING trn_generic_lineitm_storage --- ';
CREATE TABLE dbo.trn_generic_lineitm_storage(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
data_storage VARCHAR(MAX),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_generic_lineitm_storage PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE trn_generic_lineitm_storage;
GO
PRINT '--- CREATING trn_gift_registry_trans --- ';
CREATE TABLE dbo.trn_gift_registry_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
registry_id BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_gift_registry_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING trn_no_sale_trans --- ';
CREATE TABLE dbo.trn_no_sale_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
no_sale_reascode VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_no_sale_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING trn_poslog_data --- ';
CREATE TABLE dbo.trn_poslog_data(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
poslog_bytes VARBINARY(MAX),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_poslog_data PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
EXEC CREATE_PROPERTY_TABLE trn_poslog_data;
GO
PRINT '--- CREATING trn_post_void_trans --- ';
CREATE TABLE dbo.trn_post_void_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
voided_rtl_store_id INT,
voided_wkstn_id BIGINT,
voided_business_date DATETIME,
voided_trans_id BIGINT,
voided_org_id INT,
post_void_reascode VARCHAR(30),
voided_trans_entry_code VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_post_void_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING trn_raincheck --- ';
CREATE TABLE dbo.trn_raincheck(
organization_id INT NOT NULL,
rain_check_id VARCHAR(20) NOT NULL,
item_id VARCHAR(60),
sale_price DECIMAL(17, 6),
expiration_business_date DATETIME,
redeemed_flag BIT DEFAULT (0),
rtl_loc_id INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_raincheck PRIMARY KEY CLUSTERED (organization_id, rain_check_id))
GO
EXEC CREATE_PROPERTY_TABLE trn_raincheck;
GO
PRINT '--- CREATING trn_raincheck_trans --- ';
CREATE TABLE dbo.trn_raincheck_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rain_check_id VARCHAR(20) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_raincheck_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING trn_receipt_data --- ';
CREATE TABLE dbo.trn_receipt_data(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
receipt_id VARCHAR(60) NOT NULL,
receipt_data VARBINARY(MAX),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_receipt_data PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, receipt_id))
GO
EXEC CREATE_PROPERTY_TABLE trn_receipt_data;
GO
PRINT '--- CREATING trn_receipt_lookup --- ';
CREATE TABLE dbo.trn_receipt_lookup(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
business_date DATETIME NOT NULL,
trans_seq BIGINT NOT NULL,
receipt_id VARCHAR(60) NOT NULL,
receipt_url VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_receipt_lookup PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq, receipt_id))
GO
EXEC CREATE_PROPERTY_TABLE trn_receipt_lookup;
GO
PRINT '--- CREATING trn_report_data --- ';
CREATE TABLE dbo.trn_report_data(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id INT NOT NULL,
trans_seq BIGINT NOT NULL,
report_id VARCHAR(60) NOT NULL,
report_data VARBINARY(MAX),
luxury_reprint_flag BIT DEFAULT (0) NOT NULL,
internal_data_flag BIT DEFAULT (0) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_report_data PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, report_id))
GO
EXEC CREATE_PROPERTY_TABLE trn_report_data;
GO
PRINT '--- CREATING trn_reprint_receipt --- ';
CREATE TABLE dbo.trn_reprint_receipt(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
receipt_type VARCHAR(30) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_reprint_receipt PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING trn_reprint_receipt_dtl --- ';
CREATE TABLE dbo.trn_reprint_receipt_dtl(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
reprint_detail_seq INT NOT NULL,
original_gift_lineitm_seq INT,
document_type VARCHAR(30),
series_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_reprint_receipt_dtl PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, reprint_detail_seq))
GO
EXEC CREATE_PROPERTY_TABLE trn_reprint_receipt_dtl;
GO
PRINT '--- CREATING trn_temp_trans --- ';
CREATE TABLE dbo.trn_temp_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
status_code VARCHAR(30),
tran_data VARBINARY(MAX),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_temp_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING trn_trans --- ';
CREATE TABLE dbo.trn_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
begin_datetime DATETIME,
end_datetime DATETIME,
keyed_offline_flag BIT DEFAULT (0),
session_id BIGINT,
operator_party_id BIGINT,
posted_flag BIT DEFAULT (0),
dtv_class_name VARCHAR(254),
total DECIMAL(17, 6),
taxtotal DECIMAL(17, 6),
roundtotal DECIMAL(17, 6),
subtotal DECIMAL(17, 6),
trans_cancel_reascode VARCHAR(30),
trans_typcode VARCHAR(30),
trans_statcode VARCHAR(30),
post_void_flag BIT DEFAULT (0),
generic_storage_flag BIT DEFAULT (0),
begin_time_int INT,
cash_drawer_id VARCHAR(60),
flash_sales_flag BIT DEFAULT (0),
fiscal_number VARCHAR(100),
device_id VARCHAR(100),
fiscal_session_number VARCHAR(100),
trans_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING IDX_TRN_TRANS01 --- ';
CREATE INDEX IDX_TRN_TRANS01 ON dbo.trn_trans(flash_sales_flag)
GO

PRINT '--- CREATING IDX_TRN_TRANS02 --- ';
CREATE INDEX IDX_TRN_TRANS02 ON dbo.trn_trans(organization_id, trans_statcode, post_void_flag, business_date)
GO

PRINT '--- CREATING IDX_TRN_TRANS03 --- ';
CREATE INDEX IDX_TRN_TRANS03 ON dbo.trn_trans(rtl_loc_id, business_date, trans_typcode, trans_statcode, post_void_flag, organization_id, wkstn_id, trans_seq)
GO

PRINT '--- CREATING IDX_TRN_TRANS05 --- ';
CREATE INDEX IDX_TRN_TRANS05 ON dbo.trn_trans(trans_date)
GO

PRINT '--- CREATING IDX_TRN_TRANS06 --- ';
CREATE INDEX IDX_TRN_TRANS06 ON dbo.trn_trans(organization_id, device_id, fiscal_session_number, fiscal_number) WHERE (device_id IS NOT NULL )
GO

EXEC CREATE_PROPERTY_TABLE trn_trans;
GO
PRINT '--- CREATING trn_trans_attachment --- ';
CREATE TABLE dbo.trn_trans_attachment(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
attachment_type VARCHAR(60) NOT NULL,
attachment_data VARBINARY(MAX),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_trans_attachment PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, attachment_type))
GO
EXEC CREATE_PROPERTY_TABLE trn_trans_attachment;
GO
PRINT '--- CREATING trn_trans_link --- ';
CREATE TABLE dbo.trn_trans_link(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
link_rtl_loc_id INT NOT NULL,
link_business_date DATETIME NOT NULL,
link_wkstn_id BIGINT NOT NULL,
link_trans_seq BIGINT NOT NULL,
link_typcode VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_trans_link PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, link_rtl_loc_id, link_business_date, link_wkstn_id, link_trans_seq))
GO
EXEC CREATE_PROPERTY_TABLE trn_trans_link;
GO
PRINT '--- CREATING trn_trans_notes --- ';
CREATE TABLE dbo.trn_trans_notes(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
note_seq INT NOT NULL,
note_datetime DATETIME,
posted_flag BIT DEFAULT (0),
note VARCHAR(MAX),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_trans_notes PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, note_seq))
GO
EXEC CREATE_PROPERTY_TABLE trn_trans_notes;
GO
PRINT '--- CREATING trn_trans_version --- ';
CREATE TABLE dbo.trn_trans_version(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
wkstn_id BIGINT NOT NULL,
business_date DATETIME NOT NULL,
trans_seq BIGINT NOT NULL,
base_app_version VARCHAR(30),
base_app_date DATETIME,
base_schema_version VARCHAR(30),
base_schema_date DATETIME,
customer_app_version VARCHAR(30),
customer_schema_version VARCHAR(30),
customer_schema_date DATETIME,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_trn_trans_version PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq))
GO
EXEC CREATE_PROPERTY_TABLE trn_trans_version;
GO
PRINT '--- CREATING tsn_safe_bag --- ';
CREATE TABLE dbo.tsn_safe_bag(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
safe_bag_id VARCHAR(60) NOT NULL,
tndr_id VARCHAR(60),
currency_id VARCHAR(3),
bag_status VARCHAR(30),
amount DECIMAL(17, 6),
session_id BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_safe_bag PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, safe_bag_id))
GO
EXEC CREATE_PROPERTY_TABLE tsn_safe_bag;
GO
PRINT '--- CREATING tsn_serialized_tndr_count --- ';
CREATE TABLE dbo.tsn_serialized_tndr_count(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
tndr_typcode VARCHAR(30) NOT NULL,
trans_seq BIGINT NOT NULL,
serialized_tndr_count_seq INT NOT NULL,
tndr_id VARCHAR(60),
serial_number VARCHAR(60),
amt DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_serialized_tndr_count PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, tndr_typcode, trans_seq, serialized_tndr_count_seq))
GO
EXEC CREATE_PROPERTY_TABLE tsn_serialized_tndr_count;
GO
PRINT '--- CREATING tsn_session --- ';
CREATE TABLE dbo.tsn_session(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
session_id BIGINT NOT NULL,
tndr_repository_id VARCHAR(60),
employee_party_id BIGINT,
begin_datetime DATETIME,
end_datetime DATETIME,
business_date DATETIME,
statcode VARCHAR(30),
cash_drawer_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_session PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, session_id))
GO
EXEC CREATE_PROPERTY_TABLE tsn_session;
GO
PRINT '--- CREATING tsn_session_control_trans --- ';
CREATE TABLE dbo.tsn_session_control_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
typcode VARCHAR(30),
session_wkstn_seq INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_session_control_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING tsn_session_tndr --- ';
CREATE TABLE dbo.tsn_session_tndr(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
tndr_id VARCHAR(60) NOT NULL,
session_id BIGINT NOT NULL,
actual_media_count INT,
actual_media_amt DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_session_tndr PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, tndr_id, session_id))
GO
EXEC CREATE_PROPERTY_TABLE tsn_session_tndr;
GO
PRINT '--- CREATING tsn_session_wkstn --- ';
CREATE TABLE dbo.tsn_session_wkstn(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
session_id BIGINT NOT NULL,
session_wkstn_seq INT NOT NULL,
wkstn_id BIGINT,
cash_drawer_id VARCHAR(60),
begin_datetime DATETIME,
end_datetime DATETIME,
attached_flag BIT DEFAULT (0) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_session_wkstn PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, session_id, session_wkstn_seq))
GO
EXEC CREATE_PROPERTY_TABLE tsn_session_wkstn;
GO
PRINT '--- CREATING tsn_till_control_trans --- ';
CREATE TABLE dbo.tsn_till_control_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
typcode VARCHAR(30),
employee_id VARCHAR(60),
reason_code VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_till_control_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING tsn_till_ctrl_trans_detail --- ';
CREATE TABLE dbo.tsn_till_ctrl_trans_detail(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
trans_lineitm_seq INT NOT NULL,
affected_tndr_repository_id VARCHAR(60),
affected_wkstn_id BIGINT,
old_amount DECIMAL(17, 6),
new_amount DECIMAL(17, 6),
currency_id VARCHAR(3),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_till_ctrl_trans_detail PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, trans_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE tsn_till_ctrl_trans_detail;
GO
PRINT '--- CREATING tsn_tndr_control_trans --- ';
CREATE TABLE dbo.tsn_tndr_control_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
amt DECIMAL(17, 6),
reascode VARCHAR(30),
typcode VARCHAR(30),
funds_receipt_party_id BIGINT,
outbound_session_id BIGINT,
inbound_session_id BIGINT,
outbound_tndr_repository_id VARCHAR(60),
inbound_tndr_repository_id VARCHAR(60),
deposit_date DATETIME,
safe_bag_id VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_tndr_control_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
GO
PRINT '--- CREATING tsn_tndr_denomination_count --- ';
CREATE TABLE dbo.tsn_tndr_denomination_count(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
tndr_typcode VARCHAR(30) NOT NULL,
tndr_id VARCHAR(60) NOT NULL,
denomination_id VARCHAR(60) NOT NULL,
amt DECIMAL(17, 6),
media_count INT,
difference_amt DECIMAL(17, 6),
difference_media_count INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_tndr_denomination_count PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, tndr_typcode, tndr_id, denomination_id))
GO
EXEC CREATE_PROPERTY_TABLE tsn_tndr_denomination_count;
GO
PRINT '--- CREATING tsn_tndr_repository --- ';
CREATE TABLE dbo.tsn_tndr_repository(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
tndr_repository_id VARCHAR(60) NOT NULL,
typcode VARCHAR(30),
not_issuable_flag BIT DEFAULT (0) NOT NULL,
name VARCHAR(254),
description VARCHAR(254),
dflt_wkstn_id BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_tndr_repository PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, tndr_repository_id))
GO
EXEC CREATE_PROPERTY_TABLE tsn_tndr_repository;
GO
PRINT '--- CREATING tsn_tndr_repository_float --- ';
CREATE TABLE dbo.tsn_tndr_repository_float(
organization_id INT NOT NULL,
tndr_repository_id VARCHAR(60) NOT NULL,
rtl_loc_id INT NOT NULL,
currency_id VARCHAR(3) NOT NULL,
default_cash_float DECIMAL(17, 6),
last_closing_amount DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_tndr_repository_float PRIMARY KEY CLUSTERED (organization_id, tndr_repository_id, rtl_loc_id, currency_id))
GO
EXEC CREATE_PROPERTY_TABLE tsn_tndr_repository_float;
GO
PRINT '--- CREATING tsn_tndr_repository_status --- ';
CREATE TABLE dbo.tsn_tndr_repository_status(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
tndr_repository_id VARCHAR(60) NOT NULL,
issued_flag BIT DEFAULT (0) NOT NULL,
active_session_id BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_tndr_repository_status PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, tndr_repository_id))
GO
EXEC CREATE_PROPERTY_TABLE tsn_tndr_repository_status;
GO
PRINT '--- CREATING tsn_tndr_tndr_count --- ';
CREATE TABLE dbo.tsn_tndr_tndr_count(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
tndr_typcode VARCHAR(30) NOT NULL,
tndr_id VARCHAR(60) NOT NULL,
amt DECIMAL(17, 6),
media_count INT,
difference_amt DECIMAL(17, 6),
difference_media_count INT,
deposit_amt DECIMAL(17, 6),
local_currency_amt DECIMAL(17, 6),
local_currency_difference_amt DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_tndr_tndr_count PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, tndr_typcode, tndr_id))
GO
EXEC CREATE_PROPERTY_TABLE tsn_tndr_tndr_count;
GO
PRINT '--- CREATING tsn_tndr_typcode_count --- ';
CREATE TABLE dbo.tsn_tndr_typcode_count(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
tndr_typcode VARCHAR(30) NOT NULL,
amt DECIMAL(17, 6),
media_count INT,
difference_amt DECIMAL(17, 6),
difference_media_count INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_tndr_typcode_count PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, tndr_typcode))
GO
EXEC CREATE_PROPERTY_TABLE tsn_tndr_typcode_count;
GO
PRINT '--- CREATING tsn_xrtrans_lineitm --- ';
CREATE TABLE dbo.tsn_xrtrans_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
line_seq INT NOT NULL,
base_currency VARCHAR(3),
target_currency VARCHAR(3),
old_rate DECIMAL(17, 6),
new_rate DECIMAL(17, 6),
notes VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_tsn_xrtrans_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, line_seq))
GO
EXEC CREATE_PROPERTY_TABLE tsn_xrtrans_lineitm;
GO
PRINT '--- CREATING ttr_acct_credit_tndr_lineitm --- ';
CREATE TABLE dbo.ttr_acct_credit_tndr_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
cust_acct_id VARCHAR(60),
cust_acct_code VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ttr_acct_credit_tndr_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING ttr_ar_tndr_lineitm --- ';
CREATE TABLE dbo.ttr_ar_tndr_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
acct_nbr VARCHAR(60),
party_id BIGINT,
acct_user_name VARCHAR(254),
approval_code VARCHAR(30),
po_number VARCHAR(254),
adjudication_code VARCHAR(30),
auth_mthd_code VARCHAR(30),
activity_code VARCHAR(30),
entry_mthd_code VARCHAR(30),
auth_code VARCHAR(30),
acct_user_id VARCHAR(30),
orig_transmission_date_time VARCHAR(20),
orig_stan VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ttr_ar_tndr_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING IDX_TTR_AR_TNDR_LINEITM01 --- ';
CREATE INDEX IDX_TTR_AR_TNDR_LINEITM01 ON dbo.ttr_ar_tndr_lineitm(party_id)
GO

PRINT '--- CREATING ttr_check_tndr_lineitm --- ';
CREATE TABLE dbo.ttr_check_tndr_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
bank_id VARCHAR(254),
check_acct_nbr VARCHAR(254),
check_seq_nbr VARCHAR(254),
adjudication_code VARCHAR(30),
cust_birth_date DATETIME,
auth_nbr VARCHAR(254),
entry_mthd_code VARCHAR(30),
auth_mthd_code VARCHAR(30),
micr VARCHAR(254),
orig_transmission_date_time VARCHAR(20),
orig_stan VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ttr_check_tndr_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING ttr_coupon_tndr_lineitm --- ';
CREATE TABLE dbo.ttr_coupon_tndr_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
manufacturer_id VARCHAR(254),
manufacturer_family_code VARCHAR(254),
typcode VARCHAR(30),
scan_code VARCHAR(30),
expr_date DATETIME,
promotion_code VARCHAR(30),
key_entered_flag BIT DEFAULT (0),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ttr_coupon_tndr_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING ttr_credit_debit_tndr_lineitm --- ';
CREATE TABLE dbo.ttr_credit_debit_tndr_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
mediaissuer_id VARCHAR(254),
acct_nbr VARCHAR(254),
personal_id_req_typcode VARCHAR(30),
personal_id_ref_nbr VARCHAR(254),
auth_mthd_code VARCHAR(30),
adjudication_code VARCHAR(30),
entry_mthd_code VARCHAR(30),
expr_date VARCHAR(64),
auth_nbr VARCHAR(254),
ps2000 VARCHAR(254),
bank_reference_number VARCHAR(254),
customer_name VARCHAR(254),
cashback_amt DECIMAL(17, 6),
card_level_indicator VARCHAR(30),
acct_nbr_hash VARCHAR(60),
authorization_token VARCHAR(320),
transaction_reference_data VARCHAR(254),
trace_number VARCHAR(60),
tax_amt DECIMAL(17, 6),
discount_amt DECIMAL(17, 6),
freight_amt DECIMAL(17, 6),
duty_amt DECIMAL(17, 6),
orig_local_date_time VARCHAR(20),
orig_transmission_date_time VARCHAR(20),
orig_stan VARCHAR(60),
transaction_identifier VARCHAR(20),
ccv_error_code VARCHAR(10),
pos_entry_mode_change VARCHAR(10),
processing_code VARCHAR(10),
pos_entry_mode VARCHAR(10),
pos_addl_data VARCHAR(20),
network_result_indicator VARCHAR(20),
merchant_cat_code VARCHAR(4),
usage_reason_code VARCHAR(30),
dcc_currency_id VARCHAR(3),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ttr_credit_debit_tndr_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING ttr_identity_verification --- ';
CREATE TABLE dbo.ttr_identity_verification(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
identity_verification_seq INT NOT NULL,
id_typcode VARCHAR(30),
id_nbr VARCHAR(254),
issuing_authority VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ttr_identity_verification PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, identity_verification_seq))
GO
EXEC CREATE_PROPERTY_TABLE ttr_identity_verification;
GO
PRINT '--- CREATING ttr_send_check_tndr_lineitm --- ';
CREATE TABLE dbo.ttr_send_check_tndr_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
payable_to_name VARCHAR(254),
payable_to_address VARCHAR(254),
payable_to_city VARCHAR(254),
payable_to_state VARCHAR(254),
payable_to_postal_code VARCHAR(254),
reascode VARCHAR(30),
payable_to_address2 VARCHAR(254),
payable_to_address3 VARCHAR(254),
payable_to_address4 VARCHAR(254),
payable_to_apt VARCHAR(30),
payable_to_country VARCHAR(2),
payable_to_neighborhood VARCHAR(254),
payable_to_county VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ttr_send_check_tndr_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING ttr_signature --- ';
CREATE TABLE dbo.ttr_signature(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
signature VARCHAR(MAX),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ttr_signature PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE ttr_signature;
GO
PRINT '--- CREATING ttr_tndr_auth_log --- ';
CREATE TABLE dbo.ttr_tndr_auth_log(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
attempt_seq INT NOT NULL,
response_code VARCHAR(254),
reference_nbr VARCHAR(254),
error_code VARCHAR(254),
error_text VARCHAR(254),
start_timestamp DATETIME,
end_timestamp DATETIME,
approval_code VARCHAR(254),
auth_type VARCHAR(30),
customer_name VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ttr_tndr_auth_log PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, attempt_seq))
GO
EXEC CREATE_PROPERTY_TABLE ttr_tndr_auth_log;
GO
PRINT '--- CREATING ttr_tndr_lineitm --- ';
CREATE TABLE dbo.ttr_tndr_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
amt DECIMAL(17, 6),
change_flag BIT DEFAULT (0),
host_validation_flag BIT DEFAULT (0),
tndr_id VARCHAR(60),
tndr_description VARCHAR(254),
serial_nbr VARCHAR(254),
tndr_statcode VARCHAR(30),
foreign_amt DECIMAL(17, 6),
exchange_rate DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ttr_tndr_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING IDX_TTR_TNDR_LINEITM01 --- ';
CREATE INDEX IDX_TTR_TNDR_LINEITM01 ON dbo.ttr_tndr_lineitm(trans_seq, business_date, rtl_loc_id, wkstn_id, organization_id, rtrans_lineitm_seq)
GO

PRINT '--- CREATING ttr_voucher --- ';
CREATE TABLE dbo.ttr_voucher(
organization_id INT NOT NULL,
voucher_typcode VARCHAR(30) NOT NULL,
serial_nbr VARCHAR(60) NOT NULL,
issue_datetime DATETIME,
effective_date DATETIME,
expr_date DATETIME,
face_value_amt DECIMAL(17, 6),
voucher_status_code VARCHAR(30),
issue_typcode VARCHAR(30),
unspent_balance_amt DECIMAL(17, 6),
currency_id VARCHAR(3),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ttr_voucher PRIMARY KEY CLUSTERED (organization_id, voucher_typcode, serial_nbr))
GO
EXEC CREATE_PROPERTY_TABLE ttr_voucher;
GO
PRINT '--- CREATING ttr_voucher_history --- ';
CREATE TABLE dbo.ttr_voucher_history(
organization_id INT NOT NULL,
voucher_typcode VARCHAR(30) NOT NULL,
serial_nbr VARCHAR(60) NOT NULL,
history_seq BIGINT NOT NULL,
activity_code VARCHAR(30),
amt DECIMAL(17, 6),
rtrans_lineitm_seq INT,
rtl_loc_id INT,
wkstn_id BIGINT,
business_date DATETIME,
trans_seq BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ttr_voucher_history PRIMARY KEY CLUSTERED (organization_id, voucher_typcode, serial_nbr, history_seq))
GO
EXEC CREATE_PROPERTY_TABLE ttr_voucher_history;
GO
PRINT '--- CREATING ttr_voucher_tndr_lineitm --- ';
CREATE TABLE dbo.ttr_voucher_tndr_lineitm(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
voucher_typcode VARCHAR(30),
auth_mthd_code VARCHAR(30),
adjudication_code VARCHAR(30),
entry_mthd_code VARCHAR(30),
auth_code VARCHAR(30),
activity_code VARCHAR(30),
reference_nbr VARCHAR(254),
effective_date DATETIME,
expr_date DATETIME,
face_value_amt DECIMAL(17, 6),
issue_datetime DATETIME,
issue_typcode VARCHAR(30),
unspent_balance_amt DECIMAL(17, 6),
voucher_status_code VARCHAR(30),
trace_number VARCHAR(60),
orig_local_date_time VARCHAR(20),
orig_transmission_date_time VARCHAR(20),
orig_stan VARCHAR(60),
merchant_cat_code VARCHAR(4),
card_type VARCHAR(20),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_ttr_voucher_tndr_lineitm PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
PRINT '--- CREATING xom_address_mod --- ';
CREATE TABLE dbo.xom_address_mod(
organization_id INT NOT NULL,
order_id VARCHAR(60) NOT NULL,
address_seq BIGINT NOT NULL,
address1 VARCHAR(254),
address2 VARCHAR(254),
address3 VARCHAR(254),
address4 VARCHAR(254),
city VARCHAR(254),
state VARCHAR(30),
postal_code VARCHAR(30),
country VARCHAR(2),
apartment VARCHAR(30),
neighborhood VARCHAR(254),
county VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_address_mod PRIMARY KEY CLUSTERED (organization_id, order_id, address_seq))
GO
EXEC CREATE_PROPERTY_TABLE xom_address_mod;
GO
PRINT '--- CREATING xom_balance_mod --- ';
CREATE TABLE dbo.xom_balance_mod(
organization_id INT NOT NULL,
order_id VARCHAR(60) NOT NULL,
detail_seq INT NOT NULL,
detail_line_number INT NOT NULL,
mod_seq INT NOT NULL,
typcode VARCHAR(30),
amount DECIMAL(17, 6),
void_flag BIT DEFAULT (0) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_balance_mod PRIMARY KEY CLUSTERED (organization_id, order_id, detail_seq, detail_line_number, mod_seq))
GO
EXEC CREATE_PROPERTY_TABLE xom_balance_mod;
GO
PRINT '--- CREATING xom_customer_mod --- ';
CREATE TABLE dbo.xom_customer_mod(
organization_id INT NOT NULL,
order_id VARCHAR(60) NOT NULL,
customer_id VARCHAR(60),
first_name VARCHAR(60),
last_name VARCHAR(60),
telephone1 VARCHAR(32),
telephone2 VARCHAR(32),
email_address VARCHAR(254),
address_seq BIGINT,
organization_name VARCHAR(254),
salutation VARCHAR(30),
middle_name VARCHAR(60),
suffix VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_customer_mod PRIMARY KEY CLUSTERED (organization_id, order_id))
GO
PRINT '--- CREATING IDX_XOM_CUSTOMER_MOD02 --- ';
CREATE INDEX IDX_XOM_CUSTOMER_MOD02 ON dbo.xom_customer_mod(last_name, first_name, telephone1, telephone2, organization_id)
GO

PRINT '--- CREATING IDX_XOM_CUSTOMER_MOD03 --- ';
CREATE INDEX IDX_XOM_CUSTOMER_MOD03 ON dbo.xom_customer_mod(telephone1, organization_id)
GO

PRINT '--- CREATING IDX_XOM_CUSTOMER_MOD04 --- ';
CREATE INDEX IDX_XOM_CUSTOMER_MOD04 ON dbo.xom_customer_mod(telephone2, organization_id)
GO

EXEC CREATE_PROPERTY_TABLE xom_customer_mod;
GO
PRINT '--- CREATING xom_customization_mod --- ';
CREATE TABLE dbo.xom_customization_mod(
organization_id INT NOT NULL,
order_id VARCHAR(60) NOT NULL,
detail_seq INT NOT NULL,
detail_line_number INT NOT NULL,
mod_seq INT NOT NULL,
customization_code VARCHAR(30),
customization_message VARCHAR(4000),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_customization_mod PRIMARY KEY CLUSTERED (organization_id, order_id, detail_seq, detail_line_number, mod_seq))
GO
EXEC CREATE_PROPERTY_TABLE xom_customization_mod;
GO
PRINT '--- CREATING xom_fee_mod --- ';
CREATE TABLE dbo.xom_fee_mod(
organization_id INT NOT NULL,
order_id VARCHAR(60) NOT NULL,
detail_seq INT NOT NULL,
detail_line_number INT NOT NULL,
mod_seq INT NOT NULL,
typcode VARCHAR(30),
amount DECIMAL(17, 6),
void_flag BIT DEFAULT (0) NOT NULL,
tax_amount DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_fee_mod PRIMARY KEY CLUSTERED (organization_id, order_id, detail_seq, detail_line_number, mod_seq))
GO
EXEC CREATE_PROPERTY_TABLE xom_fee_mod;
GO
PRINT '--- CREATING xom_fulfillment_mod --- ';
CREATE TABLE dbo.xom_fulfillment_mod(
organization_id INT NOT NULL,
order_id VARCHAR(60) NOT NULL,
detail_seq INT NOT NULL,
detail_line_number INT NOT NULL,
loc_id VARCHAR(60),
loc_name1 VARCHAR(254),
loc_name2 VARCHAR(254),
telephone VARCHAR(32),
email_address VARCHAR(254),
address_seq BIGINT,
organization_name VARCHAR(254),
salutation VARCHAR(30),
middle_name VARCHAR(60),
suffix VARCHAR(30),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_fulfillment_mod PRIMARY KEY CLUSTERED (organization_id, order_id, detail_seq, detail_line_number))
GO
EXEC CREATE_PROPERTY_TABLE xom_fulfillment_mod;
GO
PRINT '--- CREATING xom_item_mod --- ';
CREATE TABLE dbo.xom_item_mod(
organization_id INT NOT NULL,
order_id VARCHAR(60) NOT NULL,
detail_seq INT NOT NULL,
item_id VARCHAR(60),
description VARCHAR(254),
image_url VARCHAR(254),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_item_mod PRIMARY KEY CLUSTERED (organization_id, order_id, detail_seq))
GO
EXEC CREATE_PROPERTY_TABLE xom_item_mod;
GO
PRINT '--- CREATING xom_order --- ';
CREATE TABLE dbo.xom_order(
organization_id INT NOT NULL,
order_id VARCHAR(60) NOT NULL,
order_type VARCHAR(30),
status_code VARCHAR(30),
order_date DATETIME,
order_loc_id VARCHAR(60),
subtotal DECIMAL(17, 6),
tax_amount DECIMAL(17, 6),
total DECIMAL(17, 6),
balance_due DECIMAL(17, 6),
notes VARCHAR(MAX),
ref_nbr VARCHAR(60),
additional_freight_charges DECIMAL(17, 6),
additional_charges DECIMAL(17, 6),
ship_complete_flag BIT DEFAULT (0),
freight_tax DECIMAL(17, 6),
order_message VARCHAR(4000),
gift_message VARCHAR(4000),
under_review_flag BIT DEFAULT (0),
status_code_reason VARCHAR(30),
status_code_reason_note VARCHAR(4000),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_order PRIMARY KEY CLUSTERED (organization_id, order_id))
GO
PRINT '--- CREATING IDX_XOM_ORDER02 --- ';
CREATE INDEX IDX_XOM_ORDER02 ON dbo.xom_order(order_id, order_type, status_code, organization_id)
GO

PRINT '--- CREATING IDX_XOM_ORDER03 --- ';
CREATE INDEX IDX_XOM_ORDER03 ON dbo.xom_order(order_type, status_code, organization_id)
GO

PRINT '--- CREATING IDX_XOM_ORDER04 --- ';
CREATE INDEX IDX_XOM_ORDER04 ON dbo.xom_order(status_code, organization_id)
GO

EXEC CREATE_PROPERTY_TABLE xom_order;
GO
PRINT '--- CREATING xom_order_fee --- ';
CREATE TABLE dbo.xom_order_fee(
organization_id INT NOT NULL,
order_id VARCHAR(60) NOT NULL,
detail_seq INT NOT NULL,
typcode VARCHAR(30),
amount DECIMAL(17, 6),
void_flag BIT DEFAULT (0) NOT NULL,
item_id VARCHAR(60),
tax_amount DECIMAL(17, 6),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_order_fee PRIMARY KEY CLUSTERED (organization_id, order_id, detail_seq))
GO
EXEC CREATE_PROPERTY_TABLE xom_order_fee;
GO
PRINT '--- CREATING xom_order_line --- ';
CREATE TABLE dbo.xom_order_line(
organization_id INT NOT NULL,
order_id VARCHAR(60) NOT NULL,
detail_seq INT NOT NULL,
item_id VARCHAR(60),
quantity DECIMAL(11, 4),
fulfillment_type VARCHAR(20),
item_upc_code VARCHAR(60),
item_ean_code VARCHAR(60),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_order_line PRIMARY KEY CLUSTERED (organization_id, order_id, detail_seq))
GO
EXEC CREATE_PROPERTY_TABLE xom_order_line;
GO
PRINT '--- CREATING xom_order_line_detail --- ';
CREATE TABLE dbo.xom_order_line_detail(
organization_id INT NOT NULL,
order_id VARCHAR(60) NOT NULL,
detail_seq INT NOT NULL,
detail_line_number INT NOT NULL,
external_order_id VARCHAR(60),
item_id VARCHAR(60),
quantity DECIMAL(11, 4),
fulfillment_type VARCHAR(20),
status_code VARCHAR(30),
unit_price DECIMAL(17, 6),
extended_price DECIMAL(17, 6),
tax_amount DECIMAL(17, 6),
notes VARCHAR(MAX),
selected_ship_method VARCHAR(60),
tracking_nbr VARCHAR(60),
void_flag BIT DEFAULT (0) NOT NULL,
actual_ship_method VARCHAR(60),
drop_ship_flag BIT DEFAULT (0) NOT NULL,
status_code_reason VARCHAR(30),
status_code_reason_note VARCHAR(4000),
extended_freight DECIMAL(17, 6),
customization_charge DECIMAL(17, 6),
gift_wrap_flag BIT DEFAULT (0),
ship_alone_flag BIT DEFAULT (0),
ship_weight DECIMAL(17, 6),
line_message VARCHAR(4000),
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_order_line_detail PRIMARY KEY CLUSTERED (organization_id, order_id, detail_seq, detail_line_number))
GO
EXEC CREATE_PROPERTY_TABLE xom_order_line_detail;
GO
PRINT '--- CREATING xom_order_mod --- ';
CREATE TABLE dbo.xom_order_mod(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
rtrans_lineitm_seq INT NOT NULL,
order_id VARCHAR(60),
external_order_id VARCHAR(60),
order_type VARCHAR(30),
detail_type VARCHAR(20),
detail_seq INT,
detail_line_number INT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_order_mod PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq))
GO
EXEC CREATE_PROPERTY_TABLE xom_order_mod;
GO
PRINT '--- CREATING xom_order_payment --- ';
CREATE TABLE dbo.xom_order_payment(
organization_id INT NOT NULL,
order_id VARCHAR(60) NOT NULL,
sequence INT NOT NULL,
typcode VARCHAR(30),
item_id VARCHAR(60),
amount DECIMAL(17, 6),
void_flag BIT DEFAULT (0) NOT NULL,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_order_payment PRIMARY KEY CLUSTERED (organization_id, order_id, sequence))
GO
EXEC CREATE_PROPERTY_TABLE xom_order_payment;
GO
PRINT '--- CREATING xom_source_mod --- ';
CREATE TABLE dbo.xom_source_mod(
organization_id INT NOT NULL,
order_id VARCHAR(60) NOT NULL,
detail_seq INT NOT NULL,
detail_line_number INT NOT NULL,
loc_id VARCHAR(60),
loc_type VARCHAR(30),
loc_name1 VARCHAR(254),
loc_name2 VARCHAR(254),
telephone VARCHAR(32),
email_address VARCHAR(254),
address_seq BIGINT,
create_user_id VARCHAR(256),
create_date DATETIME,
update_user_id VARCHAR(256),
update_date DATETIME,
record_state VARCHAR(30), 
CONSTRAINT pk_xom_source_mod PRIMARY KEY CLUSTERED (organization_id, order_id, detail_seq, detail_line_number))
GO
EXEC CREATE_PROPERTY_TABLE xom_source_mod;
GO
/* 
 * VIEW: Dual 
 */
 
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'Dual'))
    DROP VIEW Dual
GO

CREATE VIEW Dual(dummy)
AS
SELECT 'X'
GO

/* 
 * VIEW: Test_Connection 
 */
 
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'Test_Connection'))
    DROP VIEW Test_Connection
GO

CREATE VIEW Test_Connection(result)
AS
SELECT 1
GO

/* 
 * VIEW: [dbo].[rpt_trl_sale_lineitm_view] 
 */

IF EXISTS (Select * From information_schema.views Where table_name = 'rpt_trl_sale_lineitm_view')
  DROP VIEW rpt_trl_sale_lineitm_view;
GO

CREATE VIEW rpt_trl_sale_lineitm_view
AS
  SELECT trn.organization_id,
         trn.rtl_loc_id ,
         trn.wkstn_id ,
         trn.trans_seq ,
         tsl.rtrans_lineitm_seq ,
         trn.business_date,
         trn.begin_datetime,
         trn.end_datetime,
         trn.trans_statcode,
         trn.trans_typcode,
         trn.session_id,
         trn.operator_party_id,
         trt.cust_party_id,
         tsl.item_id,
         tsl.merch_level_1,
         tsl.quantity,
         tsl.unit_price,
         tsl.extended_amt,
         tsl.vat_amt,
         tsl.return_flag,
         tsl.net_amt,
         tsl.gross_amt,
         tsl.serial_nbr,
         tsl.sale_lineitm_typcode,
         tsl.tax_group_id,
         tsl.original_rtl_loc_id,
         tsl.original_wkstn_id,
         tsl.original_business_date,
         tsl.original_trans_seq,
         tsl.original_rtrans_lineitm_seq,
         tsl.return_reascode,
         tsl.return_comment,
         tsl.return_typcode,
         trl.void_flag,
         trl.void_lineitm_reascode,
         tsl.base_extended_price,
         tsl.rpt_base_unit_price,
         tsl.exclude_from_net_sales_flag
    FROM  
         trn_trans AS trn, 
         trl_sale_lineitm AS tsl, 
         trl_rtrans_lineitm AS trl, 
         trl_rtrans AS trt     
    WHERE 
          trn.organization_id = tsl.organization_id 
      AND trn.rtl_loc_id = tsl.rtl_loc_id
      AND trn.wkstn_id = tsl.wkstn_id 
      AND trn.business_date = tsl.business_date
      AND trn.trans_seq = tsl.trans_seq
      AND tsl.organization_id = trl.organization_id
      AND tsl.rtl_loc_id = trl.rtl_loc_id
      AND tsl.wkstn_id = trl.wkstn_id
      AND tsl.business_date = trl.business_date
      AND tsl.trans_seq = trl.trans_seq
      AND tsl.rtrans_lineitm_seq = trl.rtrans_lineitm_seq
      AND tsl.organization_id = trt.organization_id
      AND tsl.rtl_loc_id = trt.rtl_loc_id
      AND tsl.wkstn_id = trt.wkstn_id
      AND tsl.business_date = trt.business_date
      AND tsl.trans_seq = trt.trans_seq
      AND trn.trans_statcode = 'COMPLETE';
GO
/* 
 * VIEW: [dbo].[rpt_trl_stock_movement_view] 
 */

IF EXISTS (Select * From information_schema.views Where table_name = 'rpt_trl_stock_movement_view')
  DROP VIEW rpt_trl_stock_movement_view;
GO

CREATE VIEW rpt_trl_stock_movement_view
AS
SELECT itm_mov.organization_id, itm_mov.rtl_loc_id, itm_mov.business_date, itm_mov.item_id, 
      itm_mov.quantity, itm_mov.adjustment_flag
FROM

((SELECT tsl.organization_id as organization_id, tsl.rtl_loc_id as rtl_loc_id, tsl.business_date as business_date, tsl.item_id as item_id,
	quantity, case when return_flag = 0 then 1 else 0 end as adjustment_flag
	FROM rpt_trl_sale_lineitm_view tsl
	WHERE trans_seq NOT IN
          (SELECT voided_trans_id FROM trn_post_void_trans pvt
           WHERE pvt.organization_id = tsl.organization_id
           AND pvt.rtl_loc_id = tsl.rtl_loc_id
           AND pvt.wkstn_id = tsl.wkstn_id)
	AND sale_lineitm_typcode = 'SALE'
	AND tsl.void_flag = 0) 
				
UNION ALL

(SELECT inv_journal.organization_id, inv_journal.rtl_loc_id, inv_journal.business_date, inv_journal.inventory_item_id,
     quantity, case when action_code IN ('RECEIVING', 'INVENTORY_ADJUSTMENT', 'CYCLE_COUNT_ADJUSTMENT') then 0 else 1 end as adjustment_flag
FROM inv_inventory_journal inv_journal
WHERE action_code IN ('RECEIVING', 'SHIPPING', 'INVENTORY_ADJUSTMENT', 'CYCLE_COUNT_ADJUSTMENT')
      AND (source_bucket_id='ON_HAND' OR dest_bucket_id='ON_HAND'))) itm_mov 

GO

/* 
 * FUNCTION: [dbo].[fn_NLS_LOWER] 
 */

PRINT 'fn_NLS_LOWER';

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fn_NLS_LOWER')
	DROP FUNCTION dbo.fn_NLS_LOWER
GO

CREATE FUNCTION fn_NLS_LOWER (@argString nvarchar(MAX))
RETURNS nvarchar(MAX)
AS
BEGIN
	RETURN LOWER(@argString)
END
GO
/* 
 * FUNCTION: [dbo].[fn_NLS_UPPER] 
 */

PRINT 'fn_NLS_UPPER';

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fn_NLS_UPPER')
	DROP FUNCTION dbo.fn_NLS_UPPER
GO

CREATE FUNCTION fn_NLS_UPPER (@argString nvarchar(MAX))
RETURNS nvarchar(MAX)
AS
BEGIN
	RETURN UPPER(@argString)
END
GO
/* 
 * FUNCTION: [dbo].[fn_ParseDate] 
 */

PRINT 'dbo.fn_ParseDate';

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_ParseDate]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_ParseDate]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION fn_ParseDate (@argDateString varchar(24))
RETURNS datetime
AS
BEGIN
	-- Declare the return variable here
	DECLARE @vs_year varchar(4),
	 @vs_month varchar(2), 
	 @vs_day varchar(2), 
	 @vs_hour varchar(2)='00', 
	 @vs_minute varchar(2)='00', 
	 @vs_second varchar(2)='00', 
	 @vs_ms varchar(4)='000'

	SET @vs_year = LEFT(@argDateString,4)
	SET @argDateString = RIGHT(@argDateString,len(@argDateString)-5)
	SET @vs_month = LEFT(@argDateString,2)
	SET @argDateString = RIGHT(@argDateString,len(@argDateString)-3)
	SET @vs_day = LEFT(@argDateString,2)
	if len(@argDateString)>5
	begin
		SET @argDateString = RIGHT(@argDateString,len(@argDateString)-3)
		SET @vs_hour = LEFT(@argDateString,2)
		if len(@argDateString)>4
		begin
			SET @argDateString = RIGHT(@argDateString,len(@argDateString)-3)
			SET @vs_minute = LEFT(@argDateString,2)
			if len(@argDateString)>4
			begin
				SET @argDateString = RIGHT(@argDateString,len(@argDateString)-3)
				SET @vs_second = LEFT(@argDateString,2)
				if len(@argDateString)>3
					SET @vs_ms = RIGHT(@argDateString,len(@argDateString)-3)
			end
		end
	end
	-- Return the result of the function
	RETURN convert(datetime,@vs_year + '-' + @vs_month + '-' + @vs_day + ' ' + @vs_hour + ':' + @vs_minute + ':' + @vs_second + '.' + @vs_ms,120)

END
GO

/* 
 * FUNCTION: [dbo].[fn_integerListToTable] 
 */

PRINT 'dbo.fn_integerListToTable';

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_integerListToTable]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_integerListToTable]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[fn_integerListToTable] (@list nvarchar(MAX))
   RETURNS @tbl TABLE (number int NOT NULL) AS
BEGIN
   DECLARE @pos        int,
           @nextpos    int,
           @valuelen   int

   SELECT @pos = 0, @nextpos = 1

   WHILE @nextpos > 0
   BEGIN
      SELECT @nextpos = charindex(',', @list, @pos + 1)
      SELECT @valuelen = CASE WHEN @nextpos > 0
                              THEN @nextpos
                              ELSE len(@list) + 1
                         END - @pos - 1
      INSERT @tbl (number)
         VALUES (convert(int, substring(@list, @pos + 1, @valuelen)))
      SELECT @pos = @nextpos
   END
   RETURN
END


GO


IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fn_nodesInHierarchy')
DROP FUNCTION dbo.fn_nodesInHierarchy
GO

Create FUNCTION fn_nodesInHierarchy (@vorgId INT, @vorgCode NVARCHAR(30), @vorgValue NVARCHAR(60))
RETURNS TABLE
AS
RETURN (
  WITH Nodes AS (
    SELECT organization_id, org_code, org_value, parent_code, parent_value
    FROM loc_org_hierarchy chain
    WHERE organization_id = @vorgId
      AND org_code = @vorgCode
      AND org_value = @vorgValue
    UNION ALL
    SELECT node.organization_id, node.org_code, node.org_value, node.parent_code, node.parent_value
    FROM loc_org_hierarchy node
    INNER JOIN Nodes s
      ON node.organization_id = s.organization_id
      AND node.org_code = s.parent_code
      AND node.org_value = s.parent_value
    WHERE node.organization_id = @vorgId
  )
  SELECT org_code + ':' + org_value as node
  FROM Nodes
  union
  select @vorgCode + ':' + @vorgValue as node
)
GO
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fn_storesInHierarchy')
DROP FUNCTION dbo.fn_storesInHierarchy
GO

CREATE FUNCTION dbo.fn_storesInHierarchy (@vorgId INT, @vorgCode NVARCHAR(30), @vorgValue NVARCHAR(60))
RETURNS TABLE
AS
RETURN (
  WITH Stores AS (
    SELECT organization_id, org_code, org_value
    FROM loc_org_hierarchy chain
    WHERE organization_id = @vorgId
      AND org_code = @vorgCode
      AND org_value = @vorgValue
    UNION ALL
    SELECT node.organization_id, node.org_code, node.org_value
    FROM loc_org_hierarchy node
    INNER JOIN Stores s
      ON node.organization_id = s.organization_id
      AND node.parent_code = s.org_code
      AND node.parent_value = s.org_value
    WHERE node.organization_id = @vorgId
  )
  SELECT org_value
  FROM Stores
  WHERE org_code = 'STORE'
)
GO
/* 
 * PROCEDURE: [dbo].[sp_conv_to_unicode] 
 */

IF EXISTS (Select * From sysobjects Where name = 'sp_conv_to_unicode' and type = 'P')
  DROP PROCEDURE sp_conv_to_unicode;
GO

-- =============================================
-- Author:		Brett C. White
-- Create date: 2/14/12
-- Description:	Converts all char, varchar, and text fields into nchar, nvarchar, and ntext.
-- =============================================
CREATE PROCEDURE sp_conv_to_unicode 
AS
BEGIN
	begin try
	create table indexlist(
		tablename	     nvarchar(max),
		indexname	     nvarchar(max),
		sql			nvarchar(max),
		is_pk		bit,
		mult			float
	)
	end try
	begin catch
	   declare @rsql0 nvarchar(max)

	   declare icur0 CURSOR FAST_FORWARD for
	   select sql from indexlist order by is_pk desc,tablename asc

	   OPEN icur0

	   WHILE 1=1
	   BEGIN
	    FETCH NEXT FROM icur0 INTO @rsql0
	    if @@FETCH_STATUS <> 0
		    break;
	    begin try
		   print @rsql0
		   exec(@rsql0)
		   delete from indexlist where sql=@rsql0
	    end try
	    begin catch
	    end catch
	   END
	   close icur0;
	   deallocate icur0;
	end catch

	declare @ctable nvarchar(max),@csql nvarchar(max),@oldtable nvarchar(max),@isql nvarchar(max),@default nvarchar(max),@ccolumn nvarchar(max),@mult float,@error nvarchar(max);

	declare column_list CURSOR FAST_FORWARD for
	select COL.table_name,name,COLUMN_NAME,'ALTER TABLE [' + COL.table_name + '] ALTER COLUMN [' + column_name + '] n' + data_type
	+ '(' + case when(character_maximum_length=-1 or character_maximum_length>=4000) then 'max' else cast(character_maximum_length as varchar(5)) end + ') '
	+ case when(is_nullable='no') then ' NOT NULL' else ' NULL' end
	+ case when(name is not null) then '; ALTER TABLE [' + COL.table_name + '] ADD ' + case when(isnull(is_system_named,1)=0) then 'CONSTRAINT [' + name + ']' else '' end + ' DEFAULT ' + definition + ' FOR [' + COLUMN_NAME + ']' else '' end
	from INFORMATION_SCHEMA.columns COL
	inner join INFORMATION_SCHEMA.TABLES t on t.TABLE_NAME=COL.TABLE_NAME
	left join sys.default_constraints on parent_object_id = OBJECT_ID(COL.table_name) and COL_NAME(parent_object_id, parent_column_id) = column_name
	where data_type in ('varchar','char') and TABLE_TYPE like '%table%'
	order by COL.table_name,ORDINAL_POSITION

	open column_list;

	while 1=1
	BEGIN
		FETCH NEXT FROM column_list INTO @ctable,@default,@ccolumn,@csql
		if @@FETCH_STATUS <> 0
		BEGIN
			break;
		END
		declare @iname nvarchar(max),@icolumn nvarchar(max),@itype tinyint,@PK bit,@old nvarchar(max),@oldPK bit,@unique bit,@is_included bit,@ref nvarchar(max),@fktable nvarchar(max),@fill_factor nvarchar(10)

		SET @old=null
		-- Find all Foreign Keys from this table or references this table
		if exists(SELECT 1 from sysobjects f
			 inner join sysobjects c on  f.parent_obj = c.id
			 inner join sysforeignkeys r on f.id =  r.constid
			 inner join sysobjects p on r.rkeyid = p.id
			 inner  join syscolumns rc on r.rkeyid = rc.id and r.rkey = rc.colid
			 INNER JOIN INFORMATION_SCHEMA.COLUMNS col ON rc.name=col.COLUMN_NAME and c.name=col.TABLE_NAME
			 where f.type = 'F' and (p.name=@ctable or c.name=@ctable) and DATA_TYPE in ('varchar','char'))
		BEGIN
			    declare index_list CURSOR FAST_FORWARD for
				    select c.name,f.name,'alter table [' + c.name + '] WITH CHECK ADD CONSTRAINT [' + f.name
					+ '] FOREIGN KEY (' + fc.name + ISNULL(',' + fc2.name,'') + ISNULL(',' + fc3.name,'') + ISNULL(',' + fc4.name,'')
					+ ISNULL(',' + fc5.name,'') + ISNULL(',' + fc6.name,'') + ISNULL(',' + fc7.name,'') + ISNULL(',' + fc8.name,'')
					+ ISNULL(',' + fc9.name,'') + ISNULL(',' + fc10.name,'') + ISNULL(',' + fc11.name,'') + ISNULL(',' + fc12.name,'')
					+ ISNULL(',' + fc13.name,'') + ISNULL(',' + fc14.name,'') + ISNULL(',' + fc15.name,'') + ISNULL(',' + fc16.name,'') + ')'
					+ ' REFERENCES [' + p.name + '] (' + rc.name + ISNULL(',' + rc2.name,'') + ISNULL(',' + rc3.name,'') + ISNULL(',' + rc4.name,'')
				    + ISNULL(',' + rc5.name,'') + ISNULL(',' + rc6.name,'') + ISNULL(',' + rc7.name,'') + ISNULL(',' + rc8.name,'')
				    + ISNULL(',' + rc9.name,'') + ISNULL(',' + rc10.name,'') + ISNULL(',' + rc11.name,'') + ISNULL(',' + rc12.name,'') 
				    + ISNULL(',' + rc13.name,'') + ISNULL(',' + rc14.name,'') + ISNULL(',' + rc15.name,'') + ISNULL(',' + rc16.name,'') + ')'
				    + CASE WHEN(UPDATE_RULE<>'NO ACTION') then ' ON UPDATE ' + UPDATE_RULE else '' end
				    + CASE WHEN(DELETE_RULE<>'NO ACTION') then ' ON DELETE ' + DELETE_RULE else '' end
				    from sysobjects f
				    inner join sysobjects c on  f.parent_obj = c.id
				    inner join INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS IC on f.name=IC.CONSTRAINT_NAME
				    inner join sysreferences r on f.id =  r.constid
				    inner join sysobjects p on r.rkeyid = p.id
				    inner join syscolumns rc on r.rkeyid = rc.id and r.rkey1 = rc.colid
				    inner join syscolumns fc on r.fkeyid = fc.id and r.fkey1 = fc.colid
				    left join syscolumns rc2 on r.rkeyid = rc2.id and r.rkey2 = rc2.colid
				    left join syscolumns rc3 on r.rkeyid = rc3.id and r.rkey3 = rc3.colid
				    left join syscolumns rc4 on r.rkeyid = rc4.id and r.rkey4 = rc4.colid
				    left join syscolumns rc5 on r.rkeyid = rc5.id and r.rkey5 = rc5.colid
				    left join syscolumns rc6 on r.rkeyid = rc6.id and r.rkey6 = rc6.colid
				    left join syscolumns rc7 on r.rkeyid = rc7.id and r.rkey7 = rc7.colid
				    left join syscolumns rc8 on r.rkeyid = rc8.id and r.rkey8 = rc8.colid
				    left join syscolumns rc9 on r.rkeyid = rc9.id and r.rkey9 = rc9.colid
				    left join syscolumns rc10 on r.rkeyid = rc10.id and r.rkey10 = rc10.colid
				    left join syscolumns rc11 on r.rkeyid = rc11.id and r.rkey11 = rc11.colid
				    left join syscolumns rc12 on r.rkeyid = rc12.id and r.rkey12 = rc12.colid
				    left join syscolumns rc13 on r.rkeyid = rc13.id and r.rkey13 = rc13.colid
				    left join syscolumns rc14 on r.rkeyid = rc14.id and r.rkey14 = rc14.colid
				    left join syscolumns rc15 on r.rkeyid = rc15.id and r.rkey15 = rc15.colid
				    left join syscolumns rc16 on r.rkeyid = rc16.id and r.rkey16 = rc16.colid
				    left join syscolumns fc2 on r.fkeyid = fc2.id and r.fkey2 = fc2.colid
				    left join syscolumns fc3 on r.fkeyid = fc3.id and r.fkey3 = fc3.colid
				    left join syscolumns fc4 on r.fkeyid = fc4.id and r.fkey4 = fc4.colid
				    left join syscolumns fc5 on r.fkeyid = fc5.id and r.fkey5 = fc5.colid
				    left join syscolumns fc6 on r.fkeyid = fc6.id and r.fkey6 = fc6.colid
				    left join syscolumns fc7 on r.fkeyid = fc7.id and r.fkey7 = fc7.colid
				    left join syscolumns fc8 on r.fkeyid = fc8.id and r.fkey8 = fc8.colid
				    left join syscolumns fc9 on r.fkeyid = fc9.id and r.fkey9 = fc9.colid
				    left join syscolumns fc10 on r.fkeyid = fc10.id and r.fkey10 = fc10.colid
				    left join syscolumns fc11 on r.fkeyid = fc11.id and r.fkey11 = fc11.colid
				    left join syscolumns fc12 on r.fkeyid = fc12.id and r.fkey12 = fc12.colid
				    left join syscolumns fc13 on r.fkeyid = fc13.id and r.fkey13 = fc13.colid
				    left join syscolumns fc14 on r.fkeyid = fc14.id and r.fkey14 = fc14.colid
				    left join syscolumns fc15 on r.fkeyid = fc15.id and r.fkey15 = fc15.colid
				    left join syscolumns fc16 on r.fkeyid = fc16.id and r.fkey16 = fc16.colid
				 where f.type =  'F' and p.name=@ctable or c.name=@ctable
				 ORDER BY f.name
 
		    open index_list;
		    while 1=1
		    BEGIN
			    FETCH NEXT FROM index_list INTO @fktable,@iname,@isql
			    if @@FETCH_STATUS <> 0 break;
				    
			    insert into indexlist (tablename,indexname,sql) values(@fktable,@iname,@isql)

			    print 'ALTER TABLE [' + @fktable + '] DROP CONSTRAINT [' + @iname + ']'
			    exec('ALTER TABLE [' + @fktable + '] DROP CONSTRAINT [' + @iname + ']');
		    END
		    close index_list
		    deallocate index_list
		END
		  -- Find all check constraints.
		  declare index_list CURSOR FAST_FORWARD for
		  SELECT  cc.CONSTRAINT_NAME,CHECK_CLAUSE 
		  FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS cc 
		  INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE c ON cc.CONSTRAINT_NAME = c.CONSTRAINT_NAME 
		  INNER JOIN INFORMATION_SCHEMA.COLUMNS col ON c.COLUMN_NAME=col.COLUMN_NAME and c.TABLE_NAME=col.TABLE_NAME
		  where DATA_TYPE in ('varchar','char') and c.TABLE_NAME=@ctable

		  open index_list;
		  while 1=1
		  BEGIN
			  FETCH NEXT FROM index_list INTO @iname,@icolumn
			  if @@FETCH_STATUS <> 0
			  break;
			  insert into indexlist (tablename,indexname,sql) values(@ctable,@iname,'ALTER TABLE [' + @ctable + ']  WITH CHECK ADD  CONSTRAINT [' + @iname + '] CHECK  (' + @icolumn + ')')
		    
			  print 'ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @iname + ']' 
			  exec('ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @iname + ']');
		  END
		  close index_list
		  deallocate index_list
		  
		set @old = null;
		-- Find all primary keys and indexes that have char and/or varchar columns.
		if not exists (select 1 from indexlist where tablename=@ctable and is_pk is not null) and exists(SELECT 1 FROM sys.indexes ind 
			INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id and ind.index_id = ic.index_id  
			INNER JOIN sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id  
			INNER JOIN sys.tables t ON ind.object_id = t.object_id  
			INNER JOIN INFORMATION_SCHEMA.COLUMNS cl on t.name=cl.TABLE_NAME and col.name=cl.COLUMN_NAME  
			WHERE ind.type in (1, 2) and is_disabled=0 and t.name=@ctable and data_type in ('varchar','char'))
		BEGIN
			declare char_index CURSOR FAST_FORWARD for
			SELECT distinct ind.name FROM sys.indexes ind 
			INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id and ind.index_id = ic.index_id  
			INNER JOIN sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id  
			INNER JOIN sys.tables t ON ind.object_id = t.object_id  
			INNER JOIN INFORMATION_SCHEMA.COLUMNS cl on t.name=cl.TABLE_NAME and col.name=cl.COLUMN_NAME  
			WHERE ind.type in (1, 2) and is_disabled=0 and t.name=@ctable and data_type in ('varchar','char')

			open char_index
			WHILE 1=1
			BEGIN
			    FETCH NEXT FROM char_index INTO @iname
			    if @@FETCH_STATUS<>0
				    break;
			    declare index_list CURSOR FAST_FORWARD for
			    SELECT col.name,ind.type,ind.is_primary_key,ind.is_unique,is_included_column,fill_factor  
			    FROM sys.indexes ind 
			    INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id and ind.index_id = ic.index_id  
			    INNER JOIN sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id  
			    INNER JOIN sys.tables t ON ind.object_id = t.object_id  
			    WHERE ind.name=@iname and t.name=@ctable
			    ORDER BY ic.key_ordinal
    			
			    open index_list;
			    while 1=1
			    BEGIN
				    FETCH NEXT FROM index_list INTO @icolumn,@itype,@PK,@unique,@is_included,@fill_factor
				    if @@FETCH_STATUS <> 0
				    BEGIN
					    if not exists(select 1 from indexlist where indexname=@old and tablename=@ctable and is_pk is not null)
					    begin
						   SET @isql=@isql + ') WITH (FILLFACTOR = ' + @fill_factor + ')'
						   SELECT @mult=1-((SUM(max_length)-450.0)/450.0) --Shrink column length to keep key size under 900
						   FROM sys.indexes ind 
						   INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id and ind.index_id = ic.index_id  
						   INNER JOIN sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id  
						   INNER JOIN sys.tables t ON ind.object_id = t.object_id  
						   WHERE ind.type in (1, 2) and is_disabled=0 and is_included_column=0 and ind.name=@old
						   group BY ind.name
						   if (@mult>1)
	   						   insert into indexlist (tablename,indexname,sql,is_pk) values(@ctable,@old,@isql,@oldPK)
	   					   else
	   					   begin
	   						   if(@mult<.10) SET @mult=.10
	   						   insert into indexlist (tablename,indexname,sql,is_pk,mult) values(@ctable,@old,@isql,@oldPK,@mult)
	   					   end
	   					   
	   					   if @oldPK=1
							 BEGIN TRY
								 exec('ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @old + ']');
								 print 'ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @old + ']'
							 END TRY
							 BEGIN CATCH
								 print 'ERROR: ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @old + '] failed: ' + error_message()
							 END CATCH
							 else
							 BEGIN TRY
								 exec('DROP INDEX [' + @ctable + '].[' + @old + ']');
								 print 'DROP INDEX [' + @ctable + '].[' + @old + ']'
							 END TRY
							 BEGIN CATCH
								 BEGIN TRY
									SET @error=error_message()
									exec('ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @old + ']');
									print 'ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @old + ']'
								 END TRY
								 BEGIN CATCH
	   								print 'ERROR: DROP INDEX [' + @ctable + '].[' + @old + ']' + ' failed: ' + @error
	   								delete from indexlist where sql=@isql
								 END CATCH
							 END CATCH
	   				    end
					    set @mult = null;
					    break;
				    END
				    if @old is not null and @old<>@iname
				    BEGIN
					    if not exists(select 1 from indexlist where indexname=@old and tablename=@ctable and is_pk is not null)
					    begin
						   SET @isql=@isql + ') WITH (FILLFACTOR = ' + @fill_factor + ')'
						   SELECT @mult=1-((SUM(max_length)-450.0)/450.0) --Shrink column length to keep key size under 900
						   FROM sys.indexes ind 
						   INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id and ind.index_id = ic.index_id  
						   INNER JOIN sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id  
						   INNER JOIN sys.tables t ON ind.object_id = t.object_id  
						   WHERE ind.type in (1, 2) and is_disabled=0 and is_included_column=0 and ind.name=@old
						   group BY ind.name
    					    
						   if (@mult>1)
	   						   insert into indexlist (tablename,indexname,sql,is_pk) values(@ctable,@old,@isql,@oldPK)
	   					   else
	   					   begin
	   						   if(@mult<.10) SET @mult=.10
	   						   insert into indexlist (tablename,indexname,sql,is_pk,mult) values(@ctable,@old,@isql,@oldPK,@mult)
	   					   end

	   					   if @oldPK=1
							 BEGIN TRY
								 exec('ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @old + ']');
								 print 'ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @old + ']'
							 END TRY
							 BEGIN CATCH
								 print 'ERROR: ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @old + '] failed: ' + error_message()
							 END CATCH
							 else
							 BEGIN TRY
								 exec('DROP INDEX [' + @ctable + '].[' + @old + ']');
								 print 'DROP INDEX [' + @ctable + '].[' + @old + ']'
							 END TRY
							 BEGIN CATCH
								 BEGIN TRY
									SET @error=error_message()
									exec('ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @old + ']');
									print 'ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @old + ']'
								 END TRY
								 BEGIN CATCH
	   								print 'ERROR: DROP INDEX [' + @ctable + '].[' + @old + ']' + ' failed: ' + @error
	   								delete from indexlist where sql=@isql
								 END CATCH
							 END CATCH
	   				    end
					    set @mult = null;

					    if @PK=1
					    begin
						    SET @isql='ALTER TABLE [' + @ctable + '] ADD CONSTRAINT [' + @iname + '] PRIMARY KEY '
						    if @itype=1
							    SET @isql=@isql + ' CLUSTERED '
						    SET @isql=@isql + '('
					    end
					    else
					    BEGIN
						    SET @isql='CREATE '
						    if @unique=1
							    SET @isql=@isql + ' UNIQUE '
						    SET @isql=@isql + 'INDEX [' + @iname + '] ON [' + @ctable + '] ('
					    END
					    SET @oldPK=@PK
					    SET @old=@iname
				    END
				    ELSE IF @old is null
				    BEGIN
					    SET @old=@iname
					    SET @oldPK=@PK
    					
					    if @PK=1
					    begin
						    SET @isql='ALTER TABLE [' + @ctable + '] ADD CONSTRAINT [' + @iname + '] PRIMARY KEY '
						    if @itype=1
							    SET @isql=@isql + ' CLUSTERED '
						    SET @isql=@isql + '('
					    end
					    else
					    BEGIN
						    SET @isql='CREATE '
						    if @unique=1
							    SET @isql=@isql + ' UNIQUE '
						    SET @isql=@isql + 'INDEX [' + @iname + '] ON [' + @ctable + '] ('
					    END
				    END
				    ELSE IF @is_included=1 AND CHARINDEX(') INCLUDE (',@isql)=0
					    SET @isql=@isql + ') INCLUDE (';
				    ELSE
					    SET @isql=@isql + ','
    				
				    SET @isql=@isql + '[' + @icolumn + ']'
			    END
			    close index_list
			    deallocate index_list
			END
		     close char_index
		     deallocate char_index
		END
		-- Find statistics
		  declare stat_list CURSOR FAST_FORWARD for
		  select name, user_created, stats_id from sys.stats where object_id=OBJECT_ID(@ctable)
		  declare @user_created bit,@stats_id int;
		  open stat_list;
		  while 1=1
		  BEGIN
			  FETCH NEXT FROM stat_list INTO @iname,@user_created,@stats_id
			  if @@FETCH_STATUS <> 0
				break;
			  if @user_created=0
				continue;
			declare @columns nvarchar(max);
			set @columns='';
			declare scolumns cursor fast_forward for
			select col.name from sys.stats_columns sc
			INNER JOIN sys.columns col ON sc.object_id = col.object_id and sc.column_id = col.column_id  
			where sc.object_id=OBJECT_ID(@ctable) and stats_id=@stats_id order by stats_column_id

			open scolumns;
			while 1=1
			BEGIN
			    FETCH NEXT FROM scolumns INTO @icolumn
			    if @@FETCH_STATUS <> 0
				   break;
			    set @columns = @columns + @icolumn + ','
			END
			close scolumns
			deallocate scolumns
			insert into indexlist (tablename,indexname,sql) values(@ctable,@iname,'CREATE STATISTICS [' + @iname + '] ON [' + @ctable + '] (' + left(@columns,len(@columns)-1) + ')')
		    
			print 'DROP STATISTICS [' + @ctable + '].[' + @iname + ']' 
			exec('DROP STATISTICS [' + @ctable + '].[' + @iname + ']');
		  END
		  close stat_list
		  deallocate stat_list
		-- Calculate new char lengths for key columns that index key is over 900 not including include columns
		if exists(select 1 from indexlist where tablename=@ctable AND CHARINDEX(@ccolumn,sql,1)>0 and mult is not null and (CHARINDEX('INCLUDE (',sql,1)=0 or CHARINDEX(@ccolumn,sql,1)<CHARINDEX('INCLUDE (',sql,1)))
		begin
		  select top 1 @mult=ABS(mult) from indexlist where tablename=@ctable AND CHARINDEX(@ccolumn,sql)>0 and mult is not null;
		  SELECT @csql=REPLACE(@csql,cast(max_length as varchar(5)),cast(round(max_length*@mult,0) as varchar(5))) FROM sys.columns where object_id=object_id(@ctable) and name=@ccolumn and max_length>50
		end
		-- Drop default constraints.
		if @default is not null
		BEGIN
			print 'ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @default + ']'
			exec('ALTER TABLE [' + @ctable + '] DROP CONSTRAINT [' + @default + ']')
		END
		-- Convert the columns to unicode and add back the default constraints.
		begin try
		    exec(@csql)
		    print @csql
		end try
		begin catch
	   		print 'ERROR: ' + @csql + ' failed: ' + error_message()
		end catch
	END 
	
	-- Re-create the indexes, keys, and constraints
	declare @rsql nvarchar(max)

	declare icur CURSOR FAST_FORWARD for
	select sql from indexlist order by is_pk desc,tablename asc

	OPEN icur

	WHILE 1=1
	BEGIN
		FETCH NEXT FROM icur INTO @rsql
		if @@FETCH_STATUS <> 0
			break;
		begin try
		    exec(@rsql)
		    print @rsql
		    delete from indexlist where sql=@rsql
		end try
		begin catch
		    print 'ERROR: ' + @rsql + ' failed: ' + error_message()
		end catch
	END
	close icur
	deallocate icur
	
	if not exists(select 1 from indexlist)
	   drop table indexlist
	close column_list
	deallocate column_list
	
	-- Convert to Text columns to NText
	declare @ttable nvarchar(max),@tcolumn nvarchar(max);

	declare text_list CURSOR FAST_FORWARD for
	select COL.table_name,col.COLUMN_NAME
	from INFORMATION_SCHEMA.columns COL
	inner join INFORMATION_SCHEMA.TABLES t on t.TABLE_NAME=COL.TABLE_NAME
	left join sys.default_constraints on parent_object_id = OBJECT_ID(COL.table_name) and COL_NAME(parent_object_id, parent_column_id) = column_name
	where data_type in ('text') and TABLE_TYPE like '%table%'
	order by COL.table_name,ORDINAL_POSITION

	open text_list

	while 1=1
	begin
		FETCH NEXT FROM text_list INTO @ttable,@tcolumn
		if @@FETCH_STATUS <> 0
			break;
		
		SET @old=@tcolumn + '_old'
		SET @oldtable=@ttable + '.' + @tcolumn

		print 'sp_rename ' + @oldtable + ',' + @old + ', ''COLUMN''';
		EXEC sp_rename @oldtable, @old, 'COLUMN';
		
		print 'ALTER TABLE ' + @ttable + ' ADD ' + @tcolumn + ' NTEXT NULL'
		EXEC('ALTER TABLE ' + @ttable + ' ADD ' + @tcolumn + ' NTEXT NULL')
		
		print 'UPDATE ' + @ttable + ' SET ' + @tcolumn + ' = ' + @old
		EXEC('UPDATE ' + @ttable + ' SET ' + @tcolumn + ' = ' + @old)

		print 'ALTER TABLE ' + @ttable + ' DROP COLUMN ' + @old
		exec('ALTER TABLE ' + @ttable + ' DROP COLUMN ' + @old)
	end
	close text_list
	deallocate text_list
	
	PRINT 'PLEASE UPDATE THE STORED PROCEDURES, FUNCTIONS, AND TRIGGERS MANUALLY!!!'
END
GO
PRINT 'dbo.sp_defrag_indexes';
GO

IF OBJECT_ID('dbo.sp_defrag_indexes') IS NOT NULL
	DROP PROCEDURE dbo.sp_defrag_indexes;
GO
	
CREATE PROCEDURE dbo.sp_defrag_indexes (@minfrag int = 10,
					  					@minindexpages int = 1)
AS
BEGIN
-------------------------------------------------------------------------------------------------------------------
--                                                                                                               --
-- Procedure         : sp_defrag_indexes (@minfrag int, @minindexpage int)										 --
-- Parameters		 : minfrag - The minum about a fragmentation allowed in the database.  Tables with less than
--                               the amont specified will not be reorganized.
--                   : minindexpages - The minum number of pages in the indexes for a reorganized to be performed --
-- Description       : Reorganizes the tables that are fragmented with the respective minimume fragmentation 
-- Version           : 19.0                                                                                       --
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-- ST  01/30/07  Initially created
-- PGH 11/07/09  Rewriten for 2005 / 2008
-- BCW 12/02/11  Added fill factor to rebuild
-------------------------------------------------------------------------------------------------------------------
-- Declare variables

	SET NOCOUNT ON
	SET QUOTED_IDENTIFIER ON

	DECLARE @ls_version			varchar(128),
			@li_version			integer,
			@li_pos				integer,
			@table_nm			VARCHAR (128),
			@index_nm			varchar(128),
			@objectid			INT,
			@indexid			INT,
			@part_nbr			int,
			@index_typ			varchar(60),
			@index_depth		int,
			@page_cnt			int,
			@frag				DECIMAL,
			@dbname				sysname,
			@ls_sqlcmd			nvarchar(128)

	--check to verify the version, this procedure is using the DMV views introduced in 2005
	--check this is being run in a user database
	SET @ls_version = CONVERT(varchar(128), SERVERPROPERTY ('ProductVersion'))
	SET @li_pos = CHARINDEX('.', @ls_version) - 1
	SET @li_version = CONVERT(int, SUBSTRING(@ls_version, 1, @li_pos))
	IF @li_version < 9
	BEGIN
		PRINT 'Wrong Version, this procedure requires SQL SERVER 2005 or greater'
		RETURN
	END

	SELECT @dbname = db_name()
	IF @dbname IN ('master', 'msdb', 'model', 'tempdb')
	BEGIN
		PRINT 'This procedure should not be run in system databases.'
		RETURN
	END

	--begin Stage 1: Find the indexes with fragmentation
	-- Declare cursor 
	DECLARE FindIDXFrag CURSOR FOR
	SELECT object_name(i.object_id) as 'Table Name', 
			i.name as 'Index Name',
			i.object_id,
			i.index_id,
			partition_number,
			index_type_desc,
			index_depth,
			avg_fragmentation_in_percent,
			page_count
		FROM sys.dm_db_index_physical_stats(db_id(), NULL, NULL, NULL , NULL) ips
		JOIN sys.indexes i on i.object_id = ips.object_id and i.index_id = ips.index_id
		where index_type_desc in ('CLUSTERED INDEX', 'NONCLUSTERED INDEX')
		  --and avg_fragmentation_in_percent > @minfrag
		  and page_count > @minindexpages

	---- Report the ouput of showcontig for results checking
	-- SELECT * FROM #fraglist order by 1

	-- Write to output start time for information purposes
	PRINT 'Started defragmenting indexes at ' + CONVERT(VARCHAR,GETDATE())
	PRINT 'REORGANIZING:'

	-- Open the cursor
	OPEN FindIDXFrag

	-- Loop through the indexes
	FETCH NEXT
	FROM FindIDXFrag
	INTO @table_nm,
		@index_nm,
		@objectid,
		@indexid,
		@part_nbr,
		@index_typ,
		@index_depth,
		@frag,
		@page_cnt

	WHILE @@FETCH_STATUS = 0
	BEGIN

		IF @frag > @minfrag
		BEGIN 
			IF @frag > 50
				BEGIN
					PRINT 'Index ' + @index_nm + ' on ' + @table_nm + ' Rebuilt';
--					SET @ls_sqlcmd = 'ALTER INDEX [' + @index_nm + '] on [' + @table_nm + '] REBUILD WITH ONLINE=ON';  -- Online only works with Enterprise Edition
					SET @ls_sqlcmd = 'ALTER INDEX [' + @index_nm + '] on [' + @table_nm + '] REBUILD WITH (FILLFACTOR = 80)';
					print @ls_sqlcmd;
					exec (@ls_sqlcmd);
				END;
			ELSE
				BEGIN
					PRINT 'Index ' + @index_nm + ' on ' + @table_nm + ' Reorganized';
					SET @ls_sqlcmd = 'ALTER INDEX [' + @index_nm + '] on [' + @table_nm + '] REORGANIZE';
					--print @ls_sqlcmd;
					exec (@ls_sqlcmd);
					SET @ls_sqlcmd = 'UPDATE STATISTICS [' + @table_nm + '] [' + @index_nm + ']';
					--print @ls_sqlcmd;
					exec (@ls_sqlcmd);
				END;
		END;
		ELSE
			BEGIN
				PRINT 'Index ' + @index_nm + ' on ' + @table_nm + ' Statistics Updated';
				SET @ls_sqlcmd = 'UPDATE STATISTICS [' + @table_nm + '] [' + @index_nm + ']';
				--print @ls_sqlcmd;
				exec (@ls_sqlcmd);
			END;
		
		FETCH NEXT
		FROM FindIDXFrag
			INTO  @table_nm,
				@index_nm,
				@objectid,
				@indexid,
				@part_nbr,
				@index_typ,
				@index_depth,
				@frag,
				@page_cnt;
		
	END;

	-- Close and deallocate the cursor
	CLOSE FindIDXFrag;
	DEALLOCATE FindIDXFrag;

	-- move back to full mode 
	-- alter database xstore set recovery full

	-- Report on finish time for information purposes
	PRINT 'Finished defragmenting indexes at ' + CONVERT(VARCHAR,GETDATE());
END
GO
/* 
 * PROCEDURE: [dbo].[sp_fifo_detail] 
 */

PRINT 'dbo.sp_fifo_detail';

IF EXISTS (Select * From sysobjects Where name = 'sp_fifo_detail' and type = 'P')
  DROP PROCEDURE sp_fifo_detail;
GO

CREATE PROCEDURE [dbo].[sp_fifo_detail] 
    @merch_level_1_param	VARCHAR(60), 
    @merch_level_2_param	VARCHAR(60), 
    @merch_level_3_param	VARCHAR(60), 
    @merch_level_4_param	VARCHAR(60),
    @item_id_param          VARCHAR(60),
    @style_id_param         VARCHAR(60),
    @rtl_loc_id_param		VARCHAR(MAX), 
    @organization_id_param	int,
    @user_name_param		VARCHAR(30),
    @stock_val_date_param   DATETIME
 
 AS
BEGIN

  --TRUNCATE TABLE rpt_fifo_detail;
  DELETE FROM rpt_fifo_detail WHERE user_name = @user_name_param

  DECLARE 
            @organization_id		 int,
            @organization_id_a		 int,
            @item_id				 VARCHAR(60),
            @item_id_a				 VARCHAR(60),
            @description			 VARCHAR(254),
            @description_a			 VARCHAR(254),
            @style_id				 VARCHAR(60),
            @style_id_a				 VARCHAR(60),
            @style_desc			     VARCHAR(254),
            @style_desc_a			 VARCHAR(254),
            @rtl_loc_id				 int,
            @rtl_loc_id_a			 int,
            @store_name				 VARCHAR(254),
            @store_name_a			 VARCHAR(254),
            @invctl_document_id		 VARCHAR(30),
            @invctl_document_id_a	 VARCHAR(30),
            @invctl_document_nbr	 int,
            @invctl_document_nbr_a	 int,
            @create_date_timestamp	 DATETIME,
            @create_date_timestamp_a DATETIME,
            @unit_count				 DECIMAL(14,4),
            @unit_count_a			 DECIMAL(14,4),
            @current_unit_count		 DECIMAL(14,4),
            @unit_cost				 DECIMAL(17,6),
            @unit_cost_a			 DECIMAL(17,6),
            @unitCount				 DECIMAL(14,4),
            @unitCount_a			 DECIMAL(14,4),

            @comment				 VARCHAR(254),

            @current_item_id		 VARCHAR(60),
            @pending_unitCount		 DEC(14,4),
            
            @insert					 smallint;
  
  DECLARE tableCur CURSOR READ_ONLY FOR 
      SELECT MAX(sla.organization_id), MAX(COALESCE(sla.unitcount,0)) + MAX(COALESCE(ts.quantity, 0)) AS quantity, 
                  sla.item_id, MAX(i.description), MAX(style.item_id), MAX(style.description), 
		          l.rtl_loc_id, MAX(l.store_name), doc.invctl_document_id, doc.invctl_document_line_nbr,
                  doc.create_date, MAX(COALESCE(doc.unit_count,0)), MAX(COALESCE(doc.unit_cost,0))
      FROM loc_rtl_loc l, fn_integerListToTable(@rtl_loc_id_param) fn, 
			(SELECT organization_id, item_id, COALESCE(SUM(unitcount),0) AS unitcount 
				FROM inv_stock_ledger_acct, fn_integerListToTable(@rtl_loc_id_param) fn
				WHERE fn.number = rtl_loc_id 
                    AND bucket_id = 'ON_HAND'
				GROUP BY organization_id, item_id) sla
		    LEFT OUTER JOIN
            (SELECT itm_mov.organization_id, itm_mov.rtl_loc_id, itm_mov.item_id, 
	                SUM(COALESCE(quantity,0) * CASE WHEN adjustment_flag = 1 THEN 1 ELSE -1 END) AS quantity
	         FROM rpt_trl_stock_movement_view itm_mov
	         WHERE CONVERT(char(10),business_date,120) > CONVERT(char(10),@stock_val_date_param,120)
	         GROUP BY itm_mov.organization_id, itm_mov.rtl_loc_id, itm_mov.item_id) ts
	         ON sla.organization_id = ts.organization_id
	            AND sla.item_id = ts.item_id
            LEFT OUTER JOIN (
                  SELECT id.organization_id, idl.inventory_item_id, idl.rtl_loc_id , id.invctl_document_id, 
                        idl.invctl_document_line_nbr, idl.create_date, COALESCE(idl.unit_count,0) AS unit_count, COALESCE(idl.unit_cost,0) AS unit_cost
                  FROM inv_invctl_document_lineitm idl, fn_integerListToTable(@rtl_loc_id_param) fn, inv_invctl_document id
                  WHERE idl.organization_id = id.organization_id AND idl.rtl_loc_id = id.rtl_loc_id AND 
                        idl.document_typcode = id.document_typcode AND idl.invctl_document_id = id.invctl_document_id AND 
                        idl.unit_count IS NOT NULL AND idl.unit_cost IS NOT NULL AND idl.create_date IS NOT NULL AND
                        id.document_subtypcode = 'ASN'
                        AND id.status_code IN ('CLOSED', 'OPEN', 'IN_PROCESS')
                        AND CAST(FLOOR(CAST(idl.create_date AS FLOAT)) AS DATETIME) <= @stock_val_date_param
                        AND fn.number = idl.rtl_loc_id 
                        AND @organization_id_param = idl.organization_id
            ) doc
            on sla.organization_id = doc.organization_id AND 
               sla.item_id = doc.inventory_item_id
            INNER JOIN itm_item i
            ON sla.item_id = i.item_id AND
               sla.organization_id = i.organization_id
            LEFT OUTER JOIN itm_item style
            ON i.parent_item_id = style.item_id AND
               i.organization_id = style.organization_id
      WHERE @merch_level_1_param in (i.merch_level_1,'%') AND @merch_level_2_param in (i.merch_level_2,'%') AND 
            @merch_level_3_param IN (i.merch_level_3,'%') AND @merch_level_4_param IN (i.merch_level_4,'%') AND
            @item_id_param IN (i.item_id,'%') AND @style_id_param IN (i.parent_item_id,'%') AND
            sla.organization_id = l.organization_id AND 
            fn.number = l.rtl_loc_id AND 
            doc.rtl_loc_id = l.rtl_loc_id AND 
            COALESCE(sla.unitcount,0) + COALESCE(ts.quantity, 0) <> 0
      GROUP BY style.item_id, sla.item_id, doc.invctl_document_id, l.rtl_loc_id, doc.invctl_document_line_nbr, doc.create_date
      ORDER BY sla.item_id,doc.create_date DESC;
      
  BEGIN
    SET @comment = '';
    SET @current_item_id = '';
    SET @pending_unitCount = 0;
    SET @insert = 0;
    OPEN tableCur;
    FETCH tableCur INTO @organization_id, @unitcount, @item_id, @description, @style_id, @style_desc, @rtl_loc_id, @store_name, @invctl_document_id, @invctl_document_nbr,@create_date_timestamp, @unit_count, @unit_cost;
    WHILE @@FETCH_STATUS = 0 
    BEGIN
      IF @current_item_id <> @item_id
      BEGIN
        SET @current_item_id = @item_id;
        SET @pending_unitCount = @unitcount;
      END
		IF @pending_unitCount > 0
		BEGIN
		  IF @pending_unitCount < @unit_count
		  BEGIN
			SET @current_unit_count = @pending_unitCount;
			SET @pending_unitCount = 0;
		  END 
		  ELSE
		  BEGIN
			SET @current_unit_count = @unit_count ;
			SET @pending_unitCount = @pending_unitCount - @unit_count;
		  END
		  SET @insert = 1;
		END
		ELSE IF @pending_unitCount < 0
		   SET @insert = 1;
		ELSE
		   SET @insert = 0;
	      
		SET @organization_id_a = @organization_id
		SET @unitcount_a = @unitcount;
		SET @item_id_a = @item_id;
		SET @description_a = @description;
		SET @style_id_a = @style_id;
		SET @style_desc_a = @style_desc;
		SET @rtl_loc_id_a = @rtl_loc_id;
		SET @store_name_a = @store_name;
		SET @invctl_document_id_a = @invctl_document_id;
		SET @invctl_document_nbr_a = @invctl_document_nbr;
		SET @create_date_timestamp_a = @create_date_timestamp;
		SET @unit_count_a = @unit_count;
		SET @unit_cost_a = @unit_cost;
	  
		FETCH tableCur INTO @organization_id, @unitcount, @item_id, @description, @style_id, @style_desc, @rtl_loc_id, @store_name, @invctl_document_id, @invctl_document_nbr, @create_date_timestamp, @unit_count, @unit_cost;
		IF (@pending_unitCount >= 0 OR @@FETCH_STATUS < 0  OR @item_id <> @item_id_a) AND @insert = 1
		BEGIN
		  SET @comment = '';
		  IF ((@item_id_a <> @item_id AND @pending_unitCount > 0) OR @@FETCH_STATUS < 0)
		  BEGIN
			 IF @pending_unitCount > 0
			 BEGIN
			   SET @comment = '_rptLackDocStockVal';
			 END
		  END
		  IF @pending_unitCount < 0
			 BEGIN
			   SET @invctl_document_id_a = '_rptNoAvailDocStockVal';
			   SET @unit_cost_a = null;
			   SET @unit_count_a = null;
			   SET @current_unit_count = null;
			   SET @create_date_timestamp_a = null;
			   SET @comment = '_rptLackDocStockVal';
			 END
		  INSERT INTO rpt_fifo_detail (organization_id, rtl_loc_id, item_id, invctl_doc_id, user_name, invctl_doc_create_date, description, store_name, 
				 unit_count, current_unit_count, unit_cost, unit_count_a, current_cost, comment, pending_count, style_id, style_desc, invctl_doc_line_nbr)
		  VALUES(@organization_id_a, @rtl_loc_id_a, @item_id_a, @invctl_document_id_a, @user_name_param, @create_date_timestamp_a, @description_a, @store_name_a,
				 @unit_count_a, @current_unit_count, @unit_cost_a, @unitcount_a, @current_unit_count * @unit_cost_a, @comment, @pending_unitCount, @style_id_a, @style_desc_a, @invctl_document_nbr_a);
		END
    END
    CLOSE tableCur;
    DEALLOCATE tableCur;
  END
END
GO
/* 
 * PROCEDURE: [dbo].[sp_fifo_summary] 
 */

PRINT 'dbo.sp_fifo_summary';

IF EXISTS (Select * From sysobjects Where name = 'sp_fifo_summary' and type = 'P')
  DROP PROCEDURE sp_fifo_summary;
GO

CREATE PROCEDURE [dbo].[sp_fifo_summary] 
    @merch_level_1_param	VARCHAR(60), 
    @merch_level_2_param	VARCHAR(60), 
    @merch_level_3_param	VARCHAR(60), 
    @merch_level_4_param	VARCHAR(60),
    @item_id_param          VARCHAR(60),
    @style_id_param         VARCHAR(60),
    @rtl_loc_id_param		VARCHAR(MAX), 
    @organization_id_param	int,
    @user_name_param        VARCHAR(30),
    @stock_val_date_param   DATETIME
 
AS
BEGIN
  --TRUNCATE TABLE rpt_fifo;
  DELETE FROM rpt_fifo WHERE user_name = @user_name_param
  EXEC sp_fifo_detail @merch_level_1_param, @merch_level_2_param, @merch_level_3_param, @merch_level_4_param, @item_id_param, @style_id_param, @rtl_loc_id_param, @organization_id_param, @user_name_param, @stock_val_date_param
  
  DECLARE 
      @organization_id		 int,
      @unit_count			 DECIMAL(14,4),
      @item_id				 VARCHAR(60),
      @description			 VARCHAR(254),
      @style_id				 VARCHAR(60),
      @style_desc			 VARCHAR(254),
      @rtl_loc_id			 int,
      @store_name			 VARCHAR(254),
      @unit_cost			 DECIMAL(17,6),
      @comment				 VARCHAR(254)
  
  DECLARE tableCur CURSOR READ_ONLY FOR 
  
	  SELECT MAX(sla.organization_id), MAX(COALESCE(sla.unitcount,0)) + MAX(COALESCE(ts.quantity, 0)) AS quantity, 
	      sla.item_id, MAX(i.description), style.item_id, MAX(style.description), sla.rtl_loc_id, 
	      MAX(l.store_name), MAX(COALESCE(fifo_detail.unit_cost,0)), MAX(fifo_detail.comment)
	  FROM loc_rtl_loc l, fn_integerListToTable(@rtl_loc_id_param) fn, inv_stock_ledger_acct sla
	  	  
	  LEFT OUTER JOIN
	  (SELECT itm_mov.organization_id, itm_mov.rtl_loc_id, itm_mov.item_id, 
			SUM(COALESCE(quantity,0) * CASE WHEN adjustment_flag = 1 THEN 1 ELSE -1 END) AS quantity
	   FROM rpt_trl_stock_movement_view itm_mov
	   WHERE CONVERT(char(10),business_date,120) > CONVERT(CHAR(10),@stock_val_date_param,120) 
	   GROUP BY itm_mov.organization_id, itm_mov.rtl_loc_id, itm_mov.item_id) ts
	   ON sla.organization_id = ts.organization_id
     		AND sla.rtl_loc_id = ts.rtl_loc_id
			AND sla.item_id = ts.item_id
	  LEFT OUTER JOIN (
			SELECT organization_id, item_id, SUM(current_cost)/SUM(current_unit_count) as unit_cost, MAX(comment) as comment
			FROM rpt_fifo_detail
			GROUP BY organization_id, item_id ) fifo_detail
	  ON sla.organization_id = fifo_detail.organization_id AND 
		   sla.item_id = fifo_detail.item_id
	  INNER JOIN itm_item i
		ON sla.item_id = i.item_id AND
		   sla.organization_id = i.organization_id
		LEFT OUTER JOIN itm_item style
		ON i.parent_item_id = style.item_id AND 
		   i.organization_id = style.organization_id
	  WHERE @merch_level_1_param in (i.merch_level_1,'%') AND @merch_level_2_param in (i.merch_level_2,'%') AND 
            @merch_level_3_param IN (i.merch_level_3,'%') AND @merch_level_4_param IN (i.merch_level_4,'%') AND
            @item_id_param IN (i.item_id,'%') AND @style_id_param IN (i.parent_item_id,'%') AND
		    fn.number = sla.rtl_loc_id AND
		    sla.organization_id = l.organization_id AND 
		    sla.rtl_loc_id = l.rtl_loc_id AND
              sla.bucket_id = 'ON_HAND' AND
		    COALESCE(sla.unitcount,0) + COALESCE(ts.quantity, 0) <> 0
	  GROUP BY sla.rtl_loc_id, style.item_id, sla.item_id
	  ORDER BY sla.rtl_loc_id, sla.item_id DESC;

  BEGIN
    OPEN tableCur;
    FETCH tableCur INTO @organization_id, @unit_count, @item_id, @description, @style_id, @style_desc, @rtl_loc_id, @store_name, @unit_cost, @comment;
    WHILE @@FETCH_STATUS = 0 
    BEGIN
       IF @unit_cost = 0
         SET @unit_count = 0
       INSERT INTO rpt_fifo (organization_id, rtl_loc_id, store_name, item_id, user_name, description,  
		   style_id, style_desc, unit_count, unit_cost, comment)
	   VALUES(@organization_id, @rtl_loc_id, @store_name, @item_id, @user_name_param, @description, 
	       @style_id, @style_desc, @unit_count, @unit_cost, @comment); 
	   FETCH tableCur INTO @organization_id, @unit_count, @item_id, @description, @style_id, @style_desc, @rtl_loc_id, @store_name, @unit_cost, @comment;
    END
    CLOSE tableCur;
    DEALLOCATE tableCur;
  END
END
GO
/* 
 * PROCEDURE: [dbo].[sp_ins_upd_flash_sales] 
 */

IF EXISTS (Select * From sysobjects Where name = 'sp_ins_upd_flash_sales' and type = 'P')
  DROP PROCEDURE sp_ins_upd_flash_sales;
GO

CREATE PROCEDURE dbo.sp_ins_upd_flash_sales (
    @argOrgId int,
    @argRtlLocId int,
    @argBusinessDate datetime,
    @argWkstnId bigint,
    @pLineEnum varchar(254),
    @argQty decimal(11, 2),
    @argNetAmt decimal(17, 6),
    @vCurrencyId varchar(3) = 'USD')
AS
if CONTEXT_INFO()=0x0111001101110000010111110110011001101100011000010111001101101000
begin
  UPDATE rpt_flash_sales
    SET line_count = line_count + @argQty,
        line_amt = line_amt + @argNetAmt,
        update_date = getutcdate(),
        update_user_id = user
    WHERE organization_id = @argOrgId
      AND rtl_loc_id = @argRtlLocId
      AND wkstn_id = @argWkstnId
      AND business_date = @argBusinessDate
      AND line_enum = @pLineEnum;
    
  IF @@ROWCOUNT = 0  
    INSERT INTO rpt_flash_sales 
        (organization_id, rtl_loc_id, wkstn_id, line_enum, line_count, line_amt, foreign_amt, 
        business_date, currency_id, create_date, create_user_id)
      VALUES 
        (@argOrgId, @argRtlLocId, @argWkstnId, @pLineEnum, @argQty, @argNetAmt, 0, @argBusinessDate, 
        @vCurrencyId, getutcdate(), user);
end
else
	raiserror('Cannot be run directly.',10,1)
GO
/* 
 * PROCEDURE: [dbo].[sp_ins_upd_hourly_sales] 
 */

IF EXISTS (Select * From sysobjects Where name = 'sp_ins_upd_hourly_sales' and type = 'P')
  DROP PROCEDURE sp_ins_upd_hourly_sales;
GO

CREATE PROCEDURE dbo.sp_ins_upd_hourly_sales (
    @argOrgId int,
    @argRtlLocId int,
    @argBusinessDate datetime,
    @argWkstnId bigint,
    @argHour datetime,
    @argQty decimal(11, 2),
    @argNetAmt decimal(17, 6),
    @argGrossAmt decimal(17, 6),
    @argTransCount int,
    @argCurrencyId varchar(3) = 'USD')
AS
if CONTEXT_INFO()=0x0111001101110000010111110110011001101100011000010111001101101000
begin
  UPDATE rpt_sales_by_hour
    SET qty = coalesce(qty, 0) + coalesce(@argQty,0),
        trans_count = coalesce(trans_count, 0) + coalesce(@argTransCount,0),
        net_sales = coalesce(net_sales, 0) + coalesce(@argNetAmt,0),
        gross_sales = coalesce(gross_sales, 0) + coalesce(@argGrossAmt,0),
        update_date = getutcdate(),
        update_user_id = user
    WHERE organization_id = @argOrgId
      AND rtl_loc_id = @argRtlLocId
      AND wkstn_id = @argWkstnId
      AND business_date = @argBusinessDate
      AND hour = datepart(hh, @argHour);
                
IF @@ROWCOUNT = 0  
  INSERT INTO rpt_sales_by_hour (organization_id, rtl_loc_id, wkstn_id, hour, qty, trans_count,
      net_sales, business_date, gross_sales, currency_id, create_date, create_user_id)
    VALUES 
      (@argOrgId, @argRtlLocId, @argWkstnId, datepart(hh, @argHour), @argQty, @argTransCount, 
      @argNetAmt ,@argBusinessDate, @argGrossAmt, @argCurrencyId, getutcdate(), user);
end
else
	raiserror('Cannot be run directly.',10,1)
GO
/* 
 * PROCEDURE: [dbo].[sp_ins_upd_merchlvl1_sales] 
 */

IF EXISTS (Select * From sysobjects Where name = 'sp_ins_upd_merchlvl1_sales' and type = 'P')
  DROP PROCEDURE sp_ins_upd_merchlvl1_sales;
GO

CREATE PROCEDURE dbo.sp_ins_upd_merchlvl1_sales (
    @argOrgId int,
    @argRtlLocId int,
    @argBusinessDate datetime,
    @argWkstnId bigint,
    @pDeptId varchar(254),
    @argQty decimal(11, 2),
    @argNetAmt decimal(17, 6),
    @argGrossAmt decimal(17, 6),
    @argCurrencyId varchar(3) = 'USD')
AS
if CONTEXT_INFO()=0x0111001101110000010111110110011001101100011000010111001101101000
begin
  UPDATE rpt_merchlvl1_sales
    SET line_count = line_count + @argQty,
        line_amt = line_amt + @argNetAmt,
        gross_amt = gross_amt + @argGrossAmt,
        update_date = getutcdate(),
        update_user_id = user
    WHERE organization_id = @argOrgId
      AND rtl_loc_id = @argRtlLocId
      AND wkstn_id = @argWkstnId
      AND business_date = @argBusinessDate
      AND merch_level_1 = @pDeptId;
        
  IF @@ROWCOUNT = 0  
    INSERT INTO rpt_merchlvl1_sales (organization_id, rtl_loc_id, wkstn_id, merch_level_1, line_count, 
        line_amt, business_date, gross_amt, currency_id, create_date, create_user_id)
    VALUES 
        (@argOrgId, @argRtlLocId, @argWkstnId, @pDeptId, @argQty, 
        @argNetAmt ,@argBusinessDate, @argGrossAmt, @argCurrencyId, getutcdate(), user);
end
else
	raiserror('Cannot be run directly.',10,1)
GO
IF EXISTS (Select * From sysobjects Where name = 'sp_next_sequence_value' and type = 'P')
  DROP PROCEDURE sp_next_sequence_value;
GO

CREATE PROCEDURE dbo.sp_next_sequence_value(
  @argOrganizationId      int,
  @argRetailLocationId    int,
  @argWorkstationId       int,
  @argSequenceId          varchar(255),
  @argSequenceMode        varchar(60),
  @argIncrement           bit,
  @argIncrementalValue    int,
  @argMaximumValue        int,
  @argInitialValue        int,
  @argSequenceValue       int OUTPUT)
AS
BEGIN 
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
  BEGIN TRANSACTION
    DECLARE @vCurrentSequence int;
    SELECT @vCurrentSequence = t.sequence_nbr
        FROM com_sequence t WITH(TABLOCKX HOLDLOCK)
        WHERE t.organization_id = @argOrganizationId
        AND t.rtl_loc_id = @argRetailLocationId
        AND t.wkstn_id = @argWorkstationId
        AND t.sequence_id = @argSequenceId
        AND t.sequence_mode = @argSequenceMode
        
    IF @vCurrentSequence IS NOT NULL
    BEGIN
      SET @argSequenceValue = @vCurrentSequence + @argIncrementalValue
      IF(@argSequenceValue > @argMaximumValue) 
        SET @argSequenceValue = @argInitialValue + @argIncrementalValue
        
        -- handle initial value -1
      IF (@argIncrement = '1') 
      BEGIN
        UPDATE com_sequence
        SET sequence_nbr = @argSequenceValue
        WHERE organization_id = @argOrganizationId
        AND rtl_loc_id = @argRetailLocationId
        AND wkstn_id = @argWorkstationId
        AND sequence_id = @argSequenceId
        AND sequence_mode = @argSequenceMode
      END
    END
    ELSE 
    BEGIN
    
      IF (@argIncrement = '1')
        SET @argSequenceValue = @argInitialValue + @argIncrementalValue
      ELSE
        SET @argSequenceValue = @argInitialValue
      
      INSERT INTO com_sequence (organization_id, rtl_loc_id, wkstn_id, sequence_id, sequence_mode, sequence_nbr) 
      VALUES (@argOrganizationId, @argRetailLocationId, @argWorkstationId, @argSequenceId, @argSequenceMode, @argSequenceValue)
    END
  COMMIT TRANSACTION
  RETURN @argSequenceValue
END
GO
PRINT 'sp_replace_org_id';
GO
IF EXISTS (Select * From sysobjects Where name = 'sp_replace_org_id' and type = 'P')
  DROP PROCEDURE sp_replace_org_id;
GO

CREATE PROCEDURE dbo.sp_replace_org_id (
    @argNewOrgId int)
AS
-------------------------------------------------------------------------------------------------------------------
-- Procedure         :  sp_replace_org_id
-- Description       :  This procedure is designed to run in only the training database.  This will change the
--						organization_id on all table to the value passed into the procedure.
-- Version           :  19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
--               Initially created
-- PGH 08/12/10  Change the cursor to read only and added a secion to skrink the transaction log.
-- BCW 09/24/15  Changed argNewOrgId from varchar to int.
-------------------------------------------------------------------------------------------------------------------
  DECLARE @returnValue	int,
		@sql			varchar(500),
		@tableName		varchar(60),
		@LogFile		sysname
  
  DECLARE tableCur CURSOR READ_ONLY FOR 
    SELECT col.table_name 
      FROM information_schema.columns col, information_schema.tables tab
      WHERE col.table_name = tab.table_name AND 
            tab.table_type = 'BASE TABLE' AND 
            col.column_name = 'organization_id';
 
  BEGIN
    SET @returnValue = 0;
    
    OPEN tableCur;
    WHILE 1 = 1 BEGIN
      FETCH tableCur INTO @tableName;
      IF @@FETCH_STATUS <> 0
        BREAK;

      BEGIN TRY
		
        SET @sql = 'UPDATE ' + @tableName + ' SET organization_id = ' + cast(@argNewOrgId as varchar(10));
        PRINT @sql;
        EXEC (@sql);
        
      END TRY
      BEGIN CATCH
        DECLARE @errorMessage varchar(4000);
        DECLARE @errorSeverity int;
        DECLARE @errorState int;

        SELECT @errorMessage = ERROR_MESSAGE(),
               @errorSeverity = ERROR_SEVERITY(),
               @errorState = ERROR_STATE();
 
        SET @returnValue = -1;
          
        RAISERROR (@errorMessage, @errorSeverity, @errorState);
      END CATCH
    END
      
    CLOSE tableCur;
    DEALLOCATE tableCur;

	DECLARE LogFileCur CURSOR READ_ONLY FOR 
   		select name 
			from sys.database_files 
			where type = 1;
 
    OPEN LogFileCur;
	WHILE 1 = 1 BEGIN
      FETCH LogFileCur INTO @LogFile;
      IF @@FETCH_STATUS <> 0
        BREAK;
	
		DBCC SHRINKFILE (@LogFile , 0, TRUNCATEONLY);
    END
      
    CLOSE LogFileCur;
    DEALLOCATE LogFileCur;

    RETURN @returnValue;
  END
GO
/* 
 * PROCEDURE: [dbo].[sp_replace_value] 
 */

IF EXISTS (Select * From sysobjects Where name = 'sp_replace_value' and type = 'P')
  DROP PROCEDURE sp_replace_value;
GO

CREATE PROCEDURE dbo.sp_replace_value (
    @argOrgId int,
    @argColumnName varchar(60),
    @argNewValue varchar(256))
AS
  DECLARE @sql varchar(500);
  DECLARE @tableName varchar(60);
  
  DECLARE tableCursor CURSOR FOR
    SELECT col.table_name
      FROM information_schema.columns col, information_schema.tables tab
      WHERE col.table_name = tab.table_name 
        AND tab.table_type = 'BASE TABLE' 
        AND col.column_name = @argColumnName;

  BEGIN
    OPEN tableCursor;
    WHILE 1 = 1
    BEGIN
      FETCH tableCursor INTO @tableName;
      
      IF @@FETCH_STATUS <> 0
        BREAK;
        
      SET @sql = 'UPDATE ' + @tableName + ' SET ' + @argColumnName + ' = ''' + @argNewValue + ''' WHERE organization_id = ' + @argOrgId;
      EXEC (@sql);
    END
    CLOSE tableCursor;
    DEALLOCATE tableCursor;
  END
GO
IF EXISTS (Select * From sysobjects Where name = 'sp_set_sequence_value' and type = 'P')
  DROP PROCEDURE sp_set_sequence_value;
GO

CREATE PROCEDURE dbo.sp_set_sequence_value(
  @argOrganizationId      int,
  @argRetailLocationId    int,
  @argWorkstationId       int,
  @argSequenceId          varchar(255),
  @argSequenceMode        varchar(60),
  @argSequenceValue       int)
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
  BEGIN TRANSACTION
    UPDATE com_sequence WITH(TABLOCKX HOLDLOCK)
        SET sequence_nbr = @argSequenceValue
        WHERE organization_id = @argOrganizationId
        AND rtl_loc_id = @argRetailLocationId
        AND wkstn_id = @argWorkstationId
        AND sequence_id = @argSequenceId    
        And sequence_mode = @argSequenceMode
  COMMIT TRANSACTION
END
GO
PRINT 'dbo.sp_shrink';
GO

IF OBJECT_ID('dbo.sp_shrink') IS NOT NULL
	DROP PROCEDURE dbo.sp_shrink;
GO
	
CREATE PROCEDURE dbo.sp_shrink (--@as_db_name		varchar = 'xstore',
					  			  @ai_free_space	int	= 10)
AS
BEGIN
-------------------------------------------------------------------------------------------------------------------
--                     
-- Procedure         : sp_shrink (as_db_name varchar, ai_free_space int)
-- Parameters		 : as_db_name
-- Description       : 
-- Version           : 19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
	DECLARE
		@ls_owner_nm			sysname,
		@ls_table_nm			sysname,
		@ls_index_nm			sysname,
		@li_index_id			integer,
		@li_fillfactor			integer,
		@ls_domain				char(3),
		@ls_sqlcmd				varchar(256);
		
	DECLARE Table_List CURSOR FOR
		SELECT schema_name(schema_id), object_name (object_id)
			FROM sys.tables
			WHERE type = 'U'
	
	--
	-- Loop through the tables and rebuild the indexes with 100% fill factor
	--
	OPEN Table_List

	FETCH NEXT
	FROM Table_List
	INTO @ls_owner_nm, @ls_table_nm

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @ls_sqlcmd = 'ALTER INDEX ALL  on [' + @ls_owner_nm + '].[' + @ls_table_nm + '] REBUILD WITH (FILLFACTOR=100)';  -- Online only works with Enterprise Edition
		--print @ls_sqlcmd;
		exec (@ls_sqlcmd);

		FETCH NEXT
		FROM Table_List
		INTO @ls_owner_nm, @ls_table_nm
	END;
	
	CLOSE Table_List;
	DEALLOCATE Table_List;

	--
	-- Shrink the database to the desired size
	--
	print 'Free Space%: ' + str(@ai_free_space);
	DBCC SHRINKDATABASE (0, @ai_free_space);

	DECLARE Index_List CURSOR FOR
		SELECT schema_name(t.schema_id), object_name(i.object_id), i.index_id, i.name
			FROM sys.indexes i
			JOIN sys.tables t on i.object_id = t.object_id
			WHERE t.type = 'U'
			  and i.index_id > 0
	
	--
	-- Loop through the indexes and rebuild the indexes
	--
	OPEN Index_List

	FETCH NEXT
	FROM Index_List
	INTO @ls_owner_nm, @ls_table_nm, @li_index_id, @ls_index_nm

	WHILE @@FETCH_STATUS = 0
	BEGIN

		set @ls_domain = substring(@ls_table_nm, 1, 3);
		--print 'Domain: ' + @ls_domain;
		--print 'Table: ' + @ls_table_nm;
		--print 'Index: ' + @ls_index_nm;
		IF @ls_domain in ('TND', 'COM', 'DSC', 'LOC', 'TAX', 'CRM', 'DOC', 'HRS', 'SCH', 'SEC') -- Non-Transaction tables
			set @li_fillfactor = 100;
		ELSE								-- transaction tables
			IF @li_index_id < 2
				set @li_fillfactor = 90;		-- clustered / heap indexes
			ELSE
				set @li_fillfactor = 95;		-- non-clustered indexes
		
		SET @ls_sqlcmd = 'ALTER INDEX [' + @ls_index_nm + ']  on [' + @ls_owner_nm + '].[' + @ls_table_nm + '] REBUILD WITH (FILLFACTOR=' + ltrim(str(@li_fillfactor)) + ')';  -- Online only works with Enterprise Edition
		--print @ls_sqlcmd;
		exec (@ls_sqlcmd);

		FETCH NEXT
		FROM Index_List
		INTO @ls_owner_nm, @ls_table_nm, @li_index_id, @ls_index_nm
	END;
	
	CLOSE Index_List;
	DEALLOCATE Index_List;
END;
GO
/* 
 * PROCEDURE: [dbo].[sp_shrinkLog] 
 */

IF EXISTS (Select * From sysobjects Where name = 'sp_shrinkLog' and type = 'P')
  DROP PROCEDURE sp_shrinkLog;
GO

CREATE PROCEDURE sp_shrinkLog (
    @argDbName AS varchar(255), 
    @argNewSize AS int)
AS
  DECLARE @fileId AS int;
  DECLARE @serverVersion AS sql_variant;
  DECLARE logCursor CURSOR FOR 
    SELECT fileid FROM sysfiles 
      WHERE (status & 0x40) = 0x040;
  
  OPEN logCursor;
  
  FETCH NEXT FROM logCursor INTO @fileId;
  
  WHILE @@FETCH_STATUS = 0 BEGIN
    IF @argNewSize = 0  OR (SELECT size * 8 /1024 FROM sysfiles WHERE fileId=2) > @argNewSize
      DBCC SHRINKFILE (@fileId) -- default shrink
    ELSE
      DBCC SHRINKFILE (@fileId, @argNewSize);
  
    FETCH NEXT FROM logCursor INTO @fileId;
  END
  
  CLOSE logCursor;
  DEALLOCATE logCursor;
  
--
-- FB: 205359 - Removing the Backup Log because it was removed in SQL Server 2008
--
--  SELECT @serverVersion = SERVERPROPERTY('productversion');
--  
--  IF SUBSTRING(CONVERT(varchar(max), @serverVersion), 1, 2) = '10'       -- SQL Server 2008
--    BACKUP LOG @argDbName TO DISK = 'NUL:';    
--  ELSE                                          -- SQL Server 2005
--    BACKUP LOG @argDbName WITH TRUNCATE_ONLY;     
GO
-------------------------------------------------------------------------------------------------------------
--
-- Procedure         : SP_TRUNCATE_TABLE
-- Description       : This procedure executes 'truncate' statement on the given table.
-- Version           : 16.0
-------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                               --
-------------------------------------------------------------------------------------------------------------
-- WHO              DATE              DESCRIPTION                                                          --
-------------------------------------------------------------------------------------------------------------
-- Nuwan Wijekoon 02/07/2019         Initial Version
-- 
-------------------------------------------------------------------------------------------------------------


PRINT 'dbo.sp_truncate_table';

IF EXISTS (Select * From sysobjects Where name = 'sp_truncate_table' and type = 'P')
  DROP PROCEDURE dbo.sp_truncate_table;
GO

create procedure dbo.sp_truncate_table(@argTableName varchar(255))
WITH EXECUTE AS OWNER
as
declare @vPrepStatement varchar(4000)

BEGIN
  set @vPrepStatement = CONCAT('TRUNCATE TABLE dbo.', @argTableName);
  exec(@vPrepStatement);
END;

GO
/* 
 * PROCEDURE: [dbo].[sp_xstoreOrgCopy] 
 */

IF EXISTS (Select * From sysobjects Where name = 'sp_xstoreOrgCopy' and type = 'P')
  DROP PROCEDURE sp_xstoreOrgCopy;
GO

CREATE PROCEDURE dbo.sp_xstoreOrgCopy (
    @pSrcOrgId int,
    @pDstOrgId int,
    @pOption varchar(25) = NULL)
AS
  IF (@pSrcOrgId = @pDstOrgId) 
  BEGIN
    RAISERROR('Source cannot be the same as destination', 16, 1);
    RETURN(1);
  END
  
  DECLARE @tableName  varchar(255);
  DECLARE @deleteStr  varchar(255);
  DECLARE @insertStmt varchar(4000);
  DECLARE @selectStmt varchar(4000);
  DECLARE @colName    varchar(255);
  DECLARE @dataType   varchar(30);
  DECLARE @value      varchar(255);
  DECLARE @optDeletes int;
  DECLARE @optInserts int;
  DECLARE @optExec    int;

  IF LOWER(@pOption) = 'delete'
    SELECT @optDeletes = 1, @optInserts = 0, @optExec = 0;
  ELSE IF LOWER(@pOption) = 'insert'
    SELECT @optDeletes = 0, @optInserts = 1, @optExec = 0;
  ELSE IF LOWER(@pOption) = 'exec'
    SELECT @optDeletes = 1, @optInserts = 1, @optExec = 1;
  ELSE 
    SELECT @optDeletes = 1, @optInserts = 1, @optExec = 0;

  -- get a cursor of all tables that have a column named 'organization_id'  
  DECLARE tableCur CURSOR FOR
    SELECT DISTINCT tab.name 
      FROM sysobjects tab 
        INNER JOIN syscolumns col ON tab.id = col.id 
      WHERE tab.type = 'U' AND col.name = 'organization_id' ORDER BY tab.name;
  
  OPEN tableCur;

  WHILE 1 = 1 
  BEGIN
    FETCH NEXT FROM tableCur INTO @tableName;

    IF @@FETCH_STATUS <> 0 
      BREAK;

    IF @optDeletes <> 0 
      BEGIN
        SET @deleteStr = 'DELETE FROM ' + @tableName + ' WHERE organization_id = ' + CAST(@pDstOrgId AS varchar) + ';'
        PRINT (@deleteStr);
        IF @optExec <> 0 EXEC (@deleteStr);
      END

    IF @optInserts <> 0 
      BEGIN
        SET @insertStmt = 'INSERT INTO ' + @tableName + ' (organization_id';
        SET @selectStmt = 'SELECT ' + CAST(@pDstOrgId AS varchar);
    
        DECLARE colCur CURSOR FOR 
          SELECT column_name, data_type 
            FROM information_schema.columns 
           WHERE table_name = @tableName 
             AND data_type <> 'uniqueidentifier'
             AND column_name NOT IN ('organization_id', 'create_date', 'create_user_id', 'update_date', 'update_user_id', 
                                     'PROCESSED_DATE', 'PROCESSED_ID', 'record_state', 'record_timestamp', 'dss_timestamp');
        OPEN colCur;
     
        WHILE 1 = 1
          BEGIN
            FETCH NEXT FROM colCur INTO @colName, @dataType;
    
            IF @@FETCH_STATUS <> 0
              BREAK;
            
            SET @insertStmt = @insertStmt + ', ' + @colName;
            SET @selectStmt = @selectStmt + ', ';
            
            IF @colName LIKE '%_org_id'
              BEGIN
                SET @selectStmt = @selectStmt + CONVERT(varchar, @pDstOrgId);
              END
            ELSE
              BEGIN
                SET @selectStmt = @selectStmt + @colName;
              END
          END
    
        SET @insertStmt = @insertStmt + ') (' + @selectStmt + ' FROM ' + @tableName 
              + ' WHERE organization_id = ' + CAST(@pSrcOrgId AS varchar) + ');'
        
        PRINT (@insertStmt);
        IF @optExec <> 0 EXEC (@insertStmt);
          
        CLOSE colCur;
        DEALLOCATE colCur;
      END
  END

  CLOSE tableCur;
  DEALLOCATE tableCur;
  GO
GO
/* 
 * PROCEDURE: [dbo].[sp_xstore_delete_all] 
 */

IF EXISTS (Select * From sysobjects Where name = 'sp_xstore_delete_all' and type = 'P')
  DROP PROCEDURE sp_xstore_delete_all;
GO

CREATE PROCEDURE dbo.sp_xstore_delete_all
AS
  DECLARE @tableName varchar(255);
  DECLARE @sql varchar(255);
  DECLARE tableCursor CURSOR FAST_FORWARD FOR
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'dbo' AND table_type = 'BASE TABLE'
    ORDER BY table_name;
    
  OPEN tableCursor;

  WHILE 1 = 1
  BEGIN
    FETCH NEXT FROM tableCursor INTO @tableName;
    IF @@FETCH_STATUS <> 0 BREAK;
    
    SET @sql = 'TRUNCATE TABLE dbo.' + @tableName;
    PRINT @sql;
    EXEC(@sql);
  END

  CLOSE tableCursor;
  DEALLOCATE tableCursor;
GO
/* 
 * PROCEDURE: [dbo].[sp_xstore_list_all] 
 */

IF EXISTS (Select * From sysobjects Where name = 'sp_xstore_list_all' and type = 'P')
  DROP PROCEDURE sp_xstore_list_all;
GO

CREATE PROCEDURE dbo.sp_xstore_list_all
AS
  CREATE TABLE
  #t
  (
    tableName varchar(100),
    tableRowCount int
  );
  
  DECLARE @tableName varchar(255);
  DECLARE tableCursor CURSOR FOR
    SELECT name FROM sysobjects WHERE type = 'u' ORDER BY name;
  
  OPEN tableCursor;
  
  WHILE 1 = 1 BEGIN
    FETCH NEXT FROM tableCursor INTO @tableName;
    
    IF @@FETCH_STATUS <> 0
      BREAK;
  
    INSERT INTO #t (tableName, tableRowCount)
      EXEC ('SELECT ''' + @tableName + ''', COUNT(*) FROM [' + @tableName + '] WITH (NOLOCK)');
  END
  
  CLOSE tableCursor;
  DEALLOCATE tableCursor;
  SELECT * FROM #t ORDER BY tableRowCount DESC;
  DROP TABLE #t;
GO

PRINT 'dbo.sp_dbMaintenance';
GO

IF OBJECT_ID('dbo.sp_dbMaintenance') IS NOT NULL
	DROP PROCEDURE dbo.sp_dbMaintenance;
GO

CREATE PROCEDURE dbo.sp_dbMaintenance
AS
-------------------------------------------------------------------------------------------------------------------
--                                                                                                               --
-- Procedure         : sp_dbMaintenance
-- Description       : Performs standard maitntenance to a SQL Server database
--						1) Check recovery model and last backup
--						2) Index Reorganize
--						3) CheckDB
-- Version           : 19.0                                                                                       --
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-- ST  01/30/07  Initially created
-- PGH 02/11/10  Rewriten for 2005 / 2008
-------------------------------------------------------------------------------------------------------------------
DECLARE @dbName				sysname,
		@dbRecovery			varchar(60),
		@LastFullBackup		datetime,
		@LastTransBackup	datetime,
		@MinFragmentation	decimal
--		@dbBk				varchar(255),
--		@logBk				varchar(255),
--		@doBk				bit

BEGIN
	-- config
	SET @MinFragmentation = 30 --Percent
--	SET @dbBk = 'c:\xstoredb\backup\xstoreDb.bk' -- db back up destinataion
--	SET @logBk = 'c:\xstoredb\backup\xstoreLog.bk'  -- log file back up destination
--	SET @doBK = 0 -- set to true for backup
	-- end config

	SET @dbName = db_name();
	SELECT @dbRecovery = recovery_model_desc FROM SYS.DATABASES WHERE NAME =DB_NAME();
	SELECT @LastFullBackup = max(backup_finish_date) from msdb..backupset
		WHERE type = 'D'
		  AND database_name = DB_NAME();
	SELECT @LastTransBackup = max(backup_finish_date) from msdb..backupset
		WHERE type = 'L'
		  AND database_name = DB_NAME();
		  
	--
	-- 1) Check Backup Status
	--
	
	PRINT '';
	PRINT ' Database Backup Info:';
	PRINT '		Database Name:	   ' + db_name();
	PRINT '		Recovery Mode:	   ' + @dbRecovery;
	PRINT '		Last Full Backup:  ' + COALESCE(cast(@LastFullBackup as varchar), ' ');
	PRINT '     Last Trans Backup: ' + COALESCE(cast(@LastTransBackup as varchar), ' ');
	PRINT '';

	SELECT  CASE df.data_space_id
				WHEN 0 THEN 'LOG'
				ELSE  ds.name
			END AS [FileGroupName],
			df.name AS [FileName], 
			df.physical_name AS [PhysicalName], 
			round((cast(df.size as decimal) / 128) , 2) AS [Size], 
			round((FILEPROPERTY(df.name, 'SpaceUsed')/ 128.0),2) AS [SpaceUsed],	--Changed from Available Space to Used Space
			cast(ROUND(((FILEPROPERTY(df.name, 'SpaceUsed')/ 128.0) / (cast(df.size as decimal) / 128)) * 100, 0) as int)
				AS [SpaceUsedPCT],
			CASE is_percent_growth
			WHEN 0 THEN growth / 128
			ELSE growth
		END AS [Growth],
		CASE is_percent_growth
			WHEN 0 THEN 'MB'
			ELSE 'PCT'
		END AS [Growth Type],
		CASE df.max_size
			WHEN -1 THEN df.max_size
			ELSE max_size / 128
		END AS [Max Growth Size],					
		state_desc
	FROM sys.database_files df
	LEFT JOIN sys.data_spaces ds on ds.data_space_id = df.data_space_id;
	
	--
	-- 2) Index Reorganize
	--
	
	PRINT 'Reorganizing Indexes'
	EXEC dbo.sp_defrag_indexes @MinFragmentation
	
	-- 3) Update the stats
	--PRINT 'Updating Statistics'
	--EXEC sp_updatestats -- with default parameters runs stats for sample rows on all tables
	

	-- 3) Check DB
	PRINT 'CheckDB';
	DBCC CHECKDB WITH NO_INFOMSGS;

	-- 5) Backup Database
	--IF @doBk = 1
	--	BEGIN
	--		BACKUP DATABASE @dbName TO DISK = @dbBk
	--		BACKUP LOG @dbName TO DISK = @logBk
	--	END
END
GO
-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : SP_FLASH
-- Description       : Loads data into the Report tables which are then used by the flash reports.
-- Version           : 19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....     	Initial Version
-- PGH  02/23/10    Removed the currencyid paramerer, then joining the loc_rtl_loc table to get the default
--                  currencyid for the location.  If the default is not set, defaulting to 'USD'. 
-- BCW  03/07/12	Updated per Padma Golli's instructions.
-- BCW  06/21/12	Updated per Emily Tan's instructions.
-- BCW	12/05/13	Replaced the sale cursor by writing the transaction line item directly into the rpt_sale_line table.
-------------------------------------------------------------------------------------------------------------------
PRINT 'dbo.sp_flash';

IF EXISTS (Select * From sysobjects Where name = 'sp_flash' and type = 'P')
  DROP PROCEDURE sp_flash;
GO

CREATE PROCEDURE dbo.sp_flash (
@argOrganizationId int,  /*organization id*/
@argRetailLocationId int,  /*retail location or store number*/
@argBusinessDate datetime,  /*business date*/
@argWrkstnId bigint,  /*register*/
@argTransSeq bigint)  /*trans sequence*/
as

declare @old_context_info varbinary(128)=context_info();
SET CONTEXT_INFO 0x0111001101110000010111110110011001101100011000010111001101101000

declare -- Quantities
@vActualQuantity decimal(11, 2),
@vGrossQuantity decimal(11, 2),
@vQuantity decimal(11, 2),
@vTotQuantity decimal(11, 2)

declare -- Amounts
@vNetAmount decimal(17, 6),
@vGrossAmount decimal(17, 6),
@vTotGrossAmt decimal(17, 6),
@vTotNetAmt decimal(17, 6),
@vDiscountAmt decimal(17, 6),
@vOverrideAmt decimal(17, 6),
@vPaidAmt decimal(17, 6),
@vTenderAmt decimal(17, 6),
@vForeign_amt decimal(17, 6),
@vLayawayPrice decimal(17, 6),
@vUnitPrice decimal(17, 6)

declare -- Non Physical Items
@vNonPhys varchar(30),
@vNonPhysSaleType varchar(30),
@vNonPhysType varchar(30),
@vNonPhysPrice decimal(17, 6),
@vNonPhysQuantity decimal(11, 2)

declare -- Status codes
@vTransStatcode varchar(30),
@vTransTypcode varchar(30),
@vSaleLineItmTypcode varchar(30),
@vTndrStatcode varchar(60),
@vLineitemStatcode varchar(30)

declare -- others
@vTransTimeStamp datetime,
@vTransDate datetime,
@vTransCount int,
@vTndrCount int,
@vPostVoidFlag bit,
@vReturnFlag bit,
@vTaxTotal decimal(17, 6),
@vPaid varchar(30),
@vLineEnum varchar(150),
@vTndrId varchar(60),
@vItemId varchar(60),
@vRtransLineItmSeq int,
@vDepartmentId varchar(90),
@vTndridProp varchar(60),
@vCurrencyId varchar(3),
@vTndrTypCode varchar(30)

declare
@vSerialNbr varchar(60),
@vPriceModAmt decimal(17, 6),
@vPriceModReascode varchar(60),
@vNonPhysExcludeFlag bit,
@vCustPartyId varchar(60),
@vCustLastName varchar(90),
@vCustFirstName varchar(90),
@vItemDesc varchar(120),
@vBeginTimeInt int


select @vTransStatcode = trans_statcode,
@vTransTypcode = trans_typcode,
@vTransTimeStamp = begin_datetime,
@vTransDate = trans_date,
@vTaxTotal = taxtotal,
@vPostVoidFlag = post_void_flag,
@vBeginTimeInt = begin_time_int
from trn_trans with (nolock)
where organization_id = @argOrganizationId
and rtl_loc_id = @argRetailLocationId
and wkstn_id = @argWrkstnId
and business_date = @argBusinessDate
and trans_seq = @argTransSeq

if @@rowcount = 0 
  return  /* Invalid transaction */

select @vCurrencyId = max(currency_id)
from ttr_tndr_lineitm ttl with (nolock)
inner join tnd_tndr tnd with (nolock) on ttl.organization_id=tnd.organization_id and ttl.tndr_id=tnd.tndr_id
where ttl.organization_id = @argOrganizationId
and rtl_loc_id = @argRetailLocationId
and wkstn_id = @argWrkstnId
and business_date = @argBusinessDate
and trans_seq = @argTransSeq

if @vCurrencyId is null
select @vCurrencyId = max(currency_id)
from loc_rtl_loc with (nolock)
where organization_id = @argOrganizationId
and rtl_loc_id = @argRetailLocationId

-- Sundar commented the following as rpt sale line has to capture all the transactions
-- if @vTransStatcode != 'COMPLETE' and @vTransStatcode != 'SUSPEND' 
--  return

set @vTransCount = 1 /* initializing the transaction count */


-- update trans
update trn_trans set flash_sales_flag = 1
where organization_id = @argOrganizationId
and rtl_loc_id = @argRetailLocationId 
and wkstn_id = @argWrkstnId 
and trans_seq = @argTransSeq
and business_date = @argBusinessDate

-- BCW Added code to only update post voids if the original transaction 
if @vPostVoidFlag=1 and not exists(select 1 from rpt_sale_line where organization_id = @argOrganizationId
          and rtl_loc_id = @argRetailLocationId
          and wkstn_id = @argWrkstnId
          and trans_seq = @argTransSeq
          and business_date = @argBusinessDate)
      begin
       insert into rpt_sale_line WITH(ROWLOCK)
      (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq,
      quantity, actual_quantity, gross_quantity, unit_price, net_amt, gross_amt, item_id, 
      item_desc, merch_level_1, serial_nbr, return_flag, override_amt, trans_timestamp, trans_date,
      discount_amt, cust_party_id, last_name, first_name, trans_statcode, sale_lineitm_typcode, begin_time_int,
      currency_id, exclude_from_net_sales_flag)
      select tsl.organization_id, tsl.rtl_loc_id, tsl.business_date, tsl.wkstn_id, tsl.trans_seq, tsl.rtrans_lineitm_seq,
      tsl.net_quantity, tsl.quantity, tsl.gross_quantity, tsl.unit_price,
      -- For VAT taxed items there are rounding problems by which the usage of the tsl.net_amt could create problems.
      -- So, we are calculating it using the tax amount which could have more decimals and because that it is more accurate
      case when vat_amt is null then tsl.net_amt else tsl.gross_amt-tsl.vat_amt-coalesce(d.discount_amt,0) end,
      tsl.gross_amt, tsl.item_id,
      i.DESCRIPTION, coalesce(tsl.merch_level_1,i.MERCH_LEVEL_1,N'DEFAULT'), tsl.serial_nbr, tsl.return_flag, coalesce(o.override_amt,0), @vTransTimeStamp, @vTransDate, 
      coalesce(d.discount_amt,0), tr.cust_party_id, cust.last_name, cust.first_name, 'VOID', tsl.sale_lineitm_typcode, 
      @vBeginTimeInt, @vCurrencyId, tsl.exclude_from_net_sales_flag
      from trl_sale_lineitm tsl with (nolock) 
      inner join trl_rtrans_lineitm r with (nolock)
      on tsl.organization_id=r.organization_id
      and tsl.rtl_loc_id=r.rtl_loc_id
      and tsl.wkstn_id=r.wkstn_id
      and tsl.trans_seq=r.trans_seq
      and tsl.business_date=r.business_date
      and tsl.rtrans_lineitm_seq=r.rtrans_lineitm_seq
      and r.rtrans_lineitm_typcode = N'ITEM'
      left join xom_order_mod xom  with (nolock)
      on tsl.organization_id=xom.organization_id
      and tsl.rtl_loc_id=xom.rtl_loc_id
      and tsl.wkstn_id=xom.wkstn_id
      and tsl.trans_seq=xom.trans_seq
      and tsl.business_date=xom.business_date
      and tsl.rtrans_lineitm_seq=xom.rtrans_lineitm_seq
      left join xom_order_line_detail xold  with (nolock)
      on xom.organization_id=xold.organization_id
      and xom.order_id=xold.order_id
      and xom.detail_seq=xold.detail_seq
      and xom.detail_line_number=xold.detail_line_number
      left join itm_item i
      on tsl.organization_id=i.ORGANIZATION_ID
      and tsl.item_id=i.ITEM_ID
      left join (select TOP 1 extended_amt override_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
        FROM trl_rtl_price_mod with(nolock)
        WHERE void_flag = 0 and rtl_price_mod_reascode=N'PRICE_OVERRIDE' order by organization_id, rtl_loc_id, business_date, wkstn_id, rtrans_lineitm_seq, trans_seq, rtl_price_mod_seq_nbr desc) o
      on tsl.organization_id = o.organization_id 
        AND tsl.rtl_loc_id = o.rtl_loc_id
        AND tsl.business_date = o.business_date 
        AND tsl.wkstn_id = o.wkstn_id 
        AND tsl.trans_seq = o.trans_seq
        AND tsl.rtrans_lineitm_seq = o.rtrans_lineitm_seq
      left join (select sum(extended_amt) discount_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
        FROM trl_rtl_price_mod with(nolock)
        WHERE void_flag = 0 and rtl_price_mod_reascode in (N'LINE_ITEM_DISCOUNT', N'TRANSACTION_DISCOUNT',N'GROUP_DISCOUNT', N'NEW_PRICE_RULE', N'DEAL', N'ENTITLEMENT')
        group by organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq) d
      on tsl.organization_id = d.organization_id 
        AND tsl.rtl_loc_id = d.rtl_loc_id
        AND tsl.business_date = d.business_date 
        AND tsl.wkstn_id = d.wkstn_id 
        AND tsl.trans_seq = d.trans_seq
        AND tsl.rtrans_lineitm_seq = d.rtrans_lineitm_seq
      left join trl_rtrans tr with(nolock)
      on tsl.organization_id = tr.organization_id 
        AND tsl.rtl_loc_id = tr.rtl_loc_id
        AND tsl.business_date = tr.business_date 
        AND tsl.wkstn_id = tr.wkstn_id 
        AND tsl.trans_seq = tr.trans_seq
      left join crm_party cust with(nolock)
      on tsl.organization_id = cust.organization_id 
        AND tr.cust_party_id = cust.party_id
      where tsl.organization_id = @argOrganizationId
      and tsl.rtl_loc_id = @argRetailLocationId
      and tsl.wkstn_id = @argWrkstnId
      and tsl.business_date = @argBusinessDate
      and tsl.trans_seq = @argTransSeq
      and r.void_flag=0
      and ((tsl.SALE_LINEITM_TYPCODE <> N'ORDER'and (xom.detail_type IS NULL OR xold.status_code = N'FULFILLED') )
      or (tsl.SALE_LINEITM_TYPCODE = N'ORDER' and xom.detail_type in (N'FEE', N'PAYMENT') ))
  return;
  end

-- collect transaction data
if abs(@vTaxTotal) > 0 and (@vTransTypcode <> 'POST_VOID' and @vPostVoidFlag = 0) and @vTransStatcode = 'COMPLETE'
  exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
  @argWrkstnId,'TOTALTAX', 1, @vTaxTotal, @vCurrencyId          

IF @vTransTypcode = 'TENDER_CONTROL' and @vPostVoidFlag = 0
  -- process for paid in paid out 
  begin 
    select @vPaid = typcode,@vPaidAmt = amt 
    from tsn_tndr_control_trans with (nolock)  
    where typcode like 'PAID%'
          and organization_id = @argOrganizationId
          and rtl_loc_id = @argRetailLocationId
          and wkstn_id = @argWrkstnId
          and trans_seq = @argTransSeq
          and business_date = @argBusinessDate
            
    IF @@rowcount = 1
      -- it is paid in or paid out
      begin 
        if @vPaid = 'PAID_IN' or @vPaid = 'PAIDIN'
          set @vLineEnum = 'paidin'
        else
          set @vLineEnum = 'paidout'
        -- update flash sales
        if @vTransStatcode = 'COMPLETE'                
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,@vLineEnum, 1, @vPaidAmt, @vCurrencyId

      end 
  end
-- collect tenders  data
if @vPostVoidFlag = 0 and @vTransTypcode <> 'POST_VOID'
  begin

    declare tenderCursor cursor for 
    select t.amt, t.foreign_amt, t.tndr_id, t.tndr_statcode,tr.string_value,tnd.tndr_typcode
    from ttr_tndr_lineitm t with (nolock) 
    inner join trl_rtrans_lineitm r with (nolock)
    on t.organization_id=r.organization_id
    and t.rtl_loc_id=r.rtl_loc_id
    and t.wkstn_id=r.wkstn_id
    and t.trans_seq=r.trans_seq
    and t.business_date=r.business_date
    and t.rtrans_lineitm_seq=r.rtrans_lineitm_seq
  inner join tnd_tndr tnd with (nolock)
    on t.organization_id=tnd.organization_id
    and t.tndr_id=tnd.tndr_id 
  left outer join trl_rtrans_lineitm_p tr with (nolock)
    on tr.organization_id=r.organization_id
    and tr.rtl_loc_id=r.rtl_loc_id
    and tr.wkstn_id=r.wkstn_id
    and tr.trans_seq=r.trans_seq
    and tr.business_date=r.business_date
    and tr.rtrans_lineitm_seq=r.rtrans_lineitm_seq
  and property_code = 'tender_id'
    where t.organization_id = @argOrganizationId
    and t.rtl_loc_id = @argRetailLocationId 
    and t.wkstn_id = @argWrkstnId 
    and t.trans_seq = @argTransSeq
    and t.business_date = @argBusinessDate
    and r.void_flag = 0
  and t.tndr_id <> 'ACCOUNT_CREDIT'

    open tenderCursor
    while 1=1 
      begin
        fetch next from tenderCursor into @vTenderAmt,@vForeign_amt,@vTndrid,@vTndrStatcode,@vTndridProp,@vTndrTypCode           
        if @@fetch_status <> 0 
          BREAK
        if @vTndrTypCode='VOUCHER' or @vTndrStatcode <> 'Change'
          set @vTndrCount = 1  -- only for original tenders
        else 
          set @vTndrCount = 0

         if @vTndridProp IS NOT NULL
           set @vTndrid = @vTndridProp
          
        if @vLineEnum = 'paidout'
          begin
            set @vTenderAmt = coalesce(@vTenderAmt, 0) * -1
            set @vForeign_amt = coalesce(@vForeign_amt, 0) * -1
          end

        -- update flash
        if @vTransStatcode = 'COMPLETE'                
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,@vTndrid,@vTndrCount,@vTenderAmt,@vCurrencyId
    
        if @vTenderAmt > 0 and @vTransStatcode = 'COMPLETE'                
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,'TendersTakenIn', 1,@vTenderAmt,@vCurrencyId
        else
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,'TendersRefunded', 1,@vTenderAmt,@vCurrencyId
    
      end
    close tenderCursor
    deallocate tendercursor
  end

-- collect post void info
if @vTransTypcode = 'POST_VOID' or @vPostVoidFlag = 1
  begin

    set @vTransCount = -1 /* reversing the count */
    if @vPostVoidFlag = 0
      begin
        set @vPostVoidFlag = 1
        -- get the original post voided transaction and set it as original parameters
        select  @argOrganizationId = voided_org_id,
          @argRetailLocationId = voided_rtl_store_id, 
          @argWrkstnId = voided_wkstn_id, 
          @argBusinessDate = voided_business_date, 
          @argTransSeq = voided_trans_id 
        from trn_post_void_trans with (nolock)
        where organization_id = @argOrganizationId
        and rtl_loc_id = @argRetailLocationId
        and wkstn_id = @argWrkstnId
        and business_date = @argBusinessDate
        and trans_seq = @argTransSeq
    
        /* NOTE: From now on the parameter value carries the original post voided
           information rather than the current transaction information in 
           case of post void trans type. This will apply for sales data 
           processing.
        */
              
        if @@rowcount = 0 
           return -- don't know the original post voided record

    if exists(select 1 from rpt_sale_line where organization_id = @argOrganizationId
          and rtl_loc_id = @argRetailLocationId
          and wkstn_id = @argWrkstnId
          and trans_seq = @argTransSeq
          and business_date = @argBusinessDate
      and trans_statcode = 'VOID')
      return;
      end
    -- update the rpt sale line for post void
   update rpt_sale_line
    set trans_statcode='VOID'
    where organization_id = @argOrganizationId
    and rtl_loc_id = @argRetailLocationId
    and wkstn_id = @argWrkstnId
    and business_date = @argBusinessDate
    and trans_seq = @argTransSeq        

    -- reverse padin paidout
    select @vPaid = typcode,@vPaidAmt = amt 
    from tsn_tndr_control_trans with (nolock)  
    where typcode like 'PAID%'
          and organization_id = @argOrganizationId
          and rtl_loc_id = @argRetailLocationId
          and wkstn_id = @argWrkstnId
          and trans_seq = @argTransSeq
          and business_date = @argBusinessDate
            
    IF @@rowcount = 1
      -- it is paid in or paid out
      begin 
        if @vPaid = 'PAID_IN' or @vPaid = 'PAIDIN'
          set @vLineEnum = 'paidin'
        else
          set @vLineEnum = 'paidout'
        set @vPaidAmt = @vPaidAmt * -1
        -- update flash sales  
        if @vTransStatcode = 'COMPLETE'                                
          exec sp_ins_upd_flash_sales @argOrganizationId, @argRetailLocationId, @vTransDate,
          @argWrkstnId, @vLineEnum, -1, @vPaidAmt, @vCurrencyId 

      end 
    -- reverse tax
    select @vTaxTotal=taxtotal from trn_trans with (nolock)
    where organization_id = @argOrganizationId
    and rtl_loc_id = @argRetailLocationId
    and wkstn_id = @argWrkstnId
    and business_date = @argBusinessDate
    and trans_seq = @argTransSeq
    

    if abs(@vTaxTotal) > 0 and @vTransStatcode = 'COMPLETE'
      begin
        set @vTaxTotal = @vTaxTotal * -1
        exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
        @argWrkstnId,'TOTALTAX',-1,@vTaxTotal,@vCurrencyId
      end

    -- reverse tenders
    declare postVoidTenderCursor cursor for 
    select t.amt, t.foreign_amt, t.tndr_id, t.tndr_statcode,tr.string_value
    from ttr_tndr_lineitm t with (nolock) 
    inner join trl_rtrans_lineitm r with (nolock)
    on t.organization_id=r.organization_id
    and t.rtl_loc_id=r.rtl_loc_id
    and t.wkstn_id=r.wkstn_id
    and t.trans_seq=r.trans_seq
    and t.business_date=r.business_date
    and t.rtrans_lineitm_seq=r.rtrans_lineitm_seq
  left outer join trl_rtrans_lineitm_p tr with (nolock)
    on tr.organization_id=r.organization_id
    and tr.rtl_loc_id=r.rtl_loc_id
    and tr.wkstn_id=r.wkstn_id
    and tr.trans_seq=r.trans_seq
    and tr.business_date=r.business_date
    and tr.rtrans_lineitm_seq=r.rtrans_lineitm_seq
  and property_code = 'tender_id'
    where t.organization_id = @argOrganizationId
    and t.rtl_loc_id = @argRetailLocationId 
    and t.wkstn_id = @argWrkstnId 
    and t.trans_seq = @argTransSeq
    and t.business_date = @argBusinessDate
    and r.void_flag = 0
  and t.tndr_id <> 'ACCOUNT_CREDIT'

    open postVoidTenderCursor
    while 1=1 
      begin
        fetch next from postVoidTenderCursor into @vTenderAmt,@vForeign_amt,@vTndrid,@vTndrStatcode,@vTndridProp            
        if @@fetch_status <> 0 
                     BREAK
        if @vTndrStatcode <> 'Change'
          set @vTndrCount = -1  -- only for original tenders
        else 
          set @vTndrCount = 0

         if @vTndridProp IS NOT NULL
           set @vTndrid = @vTndridProp

        -- update flash
        set @vTenderAmt = @vTenderAmt * -1
 
       if @vTransStatcode = 'COMPLETE'
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,@vTndrid,@vTndrCount,@vTenderAmt,@vCurrencyId

        if @vTenderAmt < 0 and @vTransStatcode = 'COMPLETE'
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,'TendersTakenIn',-1,@vTenderAmt,@vCurrencyId
        else
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,'TendersRefunded',-1,@vTenderAmt,@vCurrencyId
  
      end
    close postVoidTenderCursor
    deallocate postVoidTenderCursor
  end

-- collect sales data
      if @vPostVoidFlag = 0 and @vTransTypcode <> 'POST_VOID' -- dont do it for rpt sale line
      begin
         insert into rpt_sale_line WITH(ROWLOCK)
        (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq,
        quantity, actual_quantity, gross_quantity, unit_price, net_amt, gross_amt, item_id, 
        item_desc, merch_level_1, serial_nbr, return_flag, override_amt, trans_timestamp, trans_date,
        discount_amt, cust_party_id, last_name, first_name, trans_statcode, sale_lineitm_typcode, 
        begin_time_int,currency_id, exclude_from_net_sales_flag)
    select tsl.organization_id, tsl.rtl_loc_id, tsl.business_date, tsl.wkstn_id, tsl.trans_seq, tsl.rtrans_lineitm_seq,
    tsl.net_quantity, tsl.quantity, tsl.gross_quantity, tsl.unit_price,
    -- For VAT taxed items there are rounding problems by which the usage of the tsl.net_amt could create problems.
    -- So, we are calculating it using the tax amount which could have more decimals and because that it is more accurate
    case when vat_amt is null then tsl.net_amt else tsl.gross_amt-tsl.vat_amt-coalesce(d.discount_amt,0) end,
    tsl.gross_amt, tsl.item_id,
    i.DESCRIPTION, coalesce(tsl.merch_level_1,i.MERCH_LEVEL_1,N'DEFAULT'), tsl.serial_nbr, tsl.return_flag, coalesce(o.override_amt,0), @vTransTimeStamp, @vTransDate,
    coalesce(d.discount_amt,0), tr.cust_party_id, cust.last_name, cust.first_name, @vTransStatcode, tsl.sale_lineitm_typcode, 
    @vBeginTimeInt, @vCurrencyId, tsl.exclude_from_net_sales_flag
    from trl_sale_lineitm tsl with (nolock) 
    inner join trl_rtrans_lineitm r with (nolock)
    on tsl.organization_id=r.organization_id
    and tsl.rtl_loc_id=r.rtl_loc_id
    and tsl.wkstn_id=r.wkstn_id
    and tsl.trans_seq=r.trans_seq
    and tsl.business_date=r.business_date
    and tsl.rtrans_lineitm_seq=r.rtrans_lineitm_seq
    and r.rtrans_lineitm_typcode = N'ITEM'
    left join xom_order_mod xom  with (nolock)
    on tsl.organization_id=xom.organization_id
    and tsl.rtl_loc_id=xom.rtl_loc_id
    and tsl.wkstn_id=xom.wkstn_id
    and tsl.trans_seq=xom.trans_seq
    and tsl.business_date=xom.business_date
    and tsl.rtrans_lineitm_seq=xom.rtrans_lineitm_seq
    left join xom_order_line_detail xold  with (nolock)
    on xom.organization_id=xold.organization_id
    and xom.order_id=xold.order_id
    and xom.detail_seq=xold.detail_seq
    and xom.detail_line_number=xold.detail_line_number
    left join itm_item i
    on tsl.organization_id=i.ORGANIZATION_ID
    and tsl.item_id=i.ITEM_ID
    left join (select top 1 extended_amt override_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
      FROM trl_rtl_price_mod with(nolock)
      WHERE void_flag = 0 and rtl_price_mod_reascode=N'PRICE_OVERRIDE' 
        and organization_id = @argOrganizationId
        and rtl_loc_id = @argRetailLocationId
        and wkstn_id = @argWrkstnId
        and business_date = @argBusinessDate
        and trans_seq = @argTransSeq 
        order by organization_id, rtl_loc_id, business_date, wkstn_id, rtrans_lineitm_seq, trans_seq, rtl_price_mod_seq_nbr desc) o
    on tsl.organization_id = o.organization_id 
      AND tsl.rtl_loc_id = o.rtl_loc_id
      AND tsl.business_date = o.business_date 
      AND tsl.wkstn_id = o.wkstn_id 
      AND tsl.trans_seq = o.trans_seq
      AND tsl.rtrans_lineitm_seq = o.rtrans_lineitm_seq
    left join (select sum(extended_amt) discount_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
      FROM trl_rtl_price_mod with(nolock)
      WHERE void_flag = 0 and rtl_price_mod_reascode in (N'LINE_ITEM_DISCOUNT', N'TRANSACTION_DISCOUNT',N'GROUP_DISCOUNT', N'NEW_PRICE_RULE', N'DEAL', N'ENTITLEMENT')
      group by organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq) d
    on tsl.organization_id = d.organization_id 
      AND tsl.rtl_loc_id = d.rtl_loc_id
      AND tsl.business_date = d.business_date 
      AND tsl.wkstn_id = d.wkstn_id 
      AND tsl.trans_seq = d.trans_seq
      AND tsl.rtrans_lineitm_seq = d.rtrans_lineitm_seq
    left join trl_rtrans tr with(nolock)
    on tsl.organization_id = tr.organization_id 
      AND tsl.rtl_loc_id = tr.rtl_loc_id
      AND tsl.business_date = tr.business_date 
      AND tsl.wkstn_id = tr.wkstn_id 
      AND tsl.trans_seq = tr.trans_seq
    left join crm_party cust with(nolock)
    on tsl.organization_id = cust.organization_id 
      AND tr.cust_party_id = cust.party_id
    where tsl.organization_id = @argOrganizationId
    and tsl.rtl_loc_id = @argRetailLocationId
    and tsl.wkstn_id = @argWrkstnId
    and tsl.business_date = @argBusinessDate
    and tsl.trans_seq = @argTransSeq
    and r.void_flag=0
    and ((tsl.SALE_LINEITM_TYPCODE <> N'ORDER'and (xom.detail_type IS NULL OR xold.status_code = N'FULFILLED') )
    or (tsl.SALE_LINEITM_TYPCODE = N'ORDER' and xom.detail_type in (N'FEE', N'PAYMENT') ))
   end
    
    if @vTransStatcode = 'COMPLETE' -- only when complete populate flash sales
    begin 
    -- returns
    select @vQuantity=sum(case @vPostVoidFlag when 0 then -1 else 1 end * coalesce(quantity,0)),@vNetAmount=sum(case @vPostVoidFlag when 1 then -1 else 1 end * coalesce(net_amt,0)) 
    from rpt_sale_line rsl with(nolock)
    where rsl.organization_id = @argOrganizationId
      and rtl_loc_id = @argRetailLocationId
      and wkstn_id = @argWrkstnId
      and business_date = @argBusinessDate
      and trans_seq= @argTransSeq
      and return_flag=1
      and coalesce(exclude_from_net_sales_flag,0)=0
 
      if abs(@vQuantity)>0 or abs(@vNetAmount)>0
        -- populate now to flash tables
        exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
        @argWrkstnId,'Returns',@vQuantity, @vNetAmount, @vCurrencyId

    select @vGrossQuantity=sum(case when return_flag=@vPostVoidFlag then 1 else -1 end * coalesce(gross_quantity,0)),
    @vQuantity=sum(case when return_flag=@vPostVoidFlag then 1 else -1 end * coalesce(quantity,0)),
    @vGrossAmount=sum(case @vPostVoidFlag when 1 then -1 else 1 end * coalesce(gross_amt,0)),
    @vNetAmount=sum(case @vPostVoidFlag when 1 then -1 else 1 end * coalesce(net_amt,0)),
    @vOverrideAmt=sum(case @vPostVoidFlag when 1 then 1 else -1 end * coalesce(override_amt,0)),
    @vDiscountAmt=sum(case @vPostVoidFlag when 1 then 1 else -1 end * coalesce(discount_amt,0)) 
    from rpt_sale_line rsl with(nolock)
    where rsl.organization_id = @argOrganizationId
      and rtl_loc_id = @argRetailLocationId
      and wkstn_id = @argWrkstnId
      and business_date = @argBusinessDate
      and trans_seq= @argTransSeq
      AND QUANTITY <> 0
      AND sale_lineitm_typcode not in ('ONHOLD','WORK_ORDER')
      and coalesce(exclude_from_net_sales_flag,0)=0

      -- For VAT taxed items there are rounding problems by which the usage of the SUM(net_amt) could create problems
      -- So we decided to set it as simple difference between the gross amount and the discount, which results in the expected value for both SALES and VAT without rounding issues
      -- We excluded the possibility to round also the tax because several reasons:
      -- 1) It will be possible that the final result is not accurate if both values have 5 as exceeding decimal
      -- 2) The value of the tax is rounded by specific legal requirements, and must match with what specified on the fiscal receipts
      -- 3) The number of decimals used for the tax amount in the database is less (6) than the one used in the calculator (10); 
      --    anyway, this last one is the most accurate, so we cannot rely on the value on the database which is at line level (rpt_sale_line) and could be affected by several roundings
      SET @vNetAmount = @vGrossAmount + @vDiscountAmt - @vTaxTotal

      -- Gross Sales update  
      if abs(@vGrossAmount) > 0
        exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
        @argWrkstnId,'GROSSSALES',@vGrossQuantity, @vGrossAmount, @vCurrencyId
      -- Net Sales update
      if abs(@vNetAmount) > 0
        exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
        @argWrkstnId,'NETSALES',@vQuantity, @vNetAmount, @vCurrencyId  
      -- Discounts
      if abs(@vOverrideAmt) > 0
        exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
        @argWrkstnId,'OVERRIDES',@vQuantity, @vOverrideAmt, @vCurrencyId  
      -- Discounts  
      if abs(@vDiscountAmt) > 0
        exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
        @argWrkstnId,'DISCOUNTS',@vQuantity, @vDiscountAmt, @vCurrencyId  

    -- Hourly sales updates (add for all the line items in the transaction)
      set @vTotQuantity = coalesce(@vTotQuantity, 0) + @vQuantity
      set @vTotNetAmt = coalesce(@vTotNetAmt, 0) + @vNetAmount
      set @vTotGrossAmt = coalesce(@vTotGrossAmt, 0) + @vGrossAmount

      -- non merchandise
      -- Non Merchandise (returns after processing)
    declare saleCursor cursor fast_forward for
    select rsl.item_id,sale_lineitm_typcode,actual_quantity,unit_price,case @vPostVoidFlag when 1 then -1 else 1 end * coalesce(gross_amt,0),case when return_flag=@vPostVoidFlag then 1 else -1 end * coalesce(gross_quantity,0),merch_level_1,case @vPostVoidFlag when 1 then -1 else 1 end * coalesce(net_amt,0),case when return_flag=@vPostVoidFlag then 1 else -1 end * coalesce(quantity,0),return_flag
    from rpt_sale_line rsl with(nolock)
    where rsl.organization_id = @argOrganizationId
      and rtl_loc_id = @argRetailLocationId
      and wkstn_id = @argWrkstnId
      and business_date = @argBusinessDate
      and trans_seq= @argTransSeq
      AND QUANTITY <> 0
      AND sale_lineitm_typcode not in ('ONHOLD','WORK_ORDER')
      and coalesce(exclude_from_net_sales_flag,0)=0

    open saleCursor

    while 1=1
    begin

    fetch from saleCursor into @vItemId,@vSaleLineItmTypcode,@vActualQuantity,@vUnitPrice,@vGrossAmount,@vGrossQuantity,@vDepartmentId,@vNetAmount,@vQuantity,@vReturnFlag;
    if @@FETCH_STATUS <> 0
    break;

      select @vNonPhysType = non_phys_item_typcode from itm_non_phys_item with (nolock)
      where item_id = @vItemId and organization_id = @argOrganizationId    
      IF @@rowcount = 1
        begin      
        -- check for layaway or sp. order payment / deposit
          if @vPostVoidFlag <> @vReturnFlag
            begin
              set @vNonPhysPrice = @vUnitPrice * -1
              set @vNonPhysQuantity = @vActualQuantity * -1
            end
          else
            begin
              set @vNonPhysPrice = @vUnitPrice
              set @vNonPhysQuantity = @vActualQuantity
            end
        
          if @vNonPhysType = 'LAYAWAY_DEPOSIT'
            set @vNonPhys = 'LayawayDeposits'
          else if @vNonPhysType = 'LAYAWAY_PAYMENT'
            set @vNonPhys = 'LayawayPayments'
          else if @vNonPhysType = 'SP_ORDER_DEPOSIT'
            set @vNonPhys = 'SpOrderDeposits'        
          else if @vNonPhysType = 'SP_ORDER_PAYMENT'
            set @vNonPhys = 'SpOrderPayments'        
          else if @vNonPhysType = 'PRESALE_DEPOSIT'
            set @vNonPhys = 'PresaleDeposits'
          else if @vNonPhysType = 'PRESALE_PAYMENT'
            set @vNonPhys = 'PresalePayments'
          else if @vNonPhysType = 'ONHOLD_DEPOSIT'
            set @vNonPhys = 'OnholdDeposits'
          else if @vNonPhysType = 'ONHOLD_PAYMENT'
            set @vNonPhys = 'OnholdPayments'
          else if @vNonPhysType = 'LOCALORDER_DEPOSIT'
            set @vNonPhys = 'LocalInventoryOrderDeposits'
          else if @vNonPhysType = 'LOCALORDER_PAYMENT'
            set @vNonPhys = 'LocalInventoryOrderPayments'
          else 
            begin
              set @vNonPhys = 'NonMerchandise'
              set @vNonPhysPrice = @vGrossAmount
              set @vNonPhysQuantity = @vGrossQuantity
            end
          -- update flash sales for non physical payments / deposits
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,@vNonPhys,@vNonPhysQuantity, @vNonphysPrice, @vCurrencyId
        end  
      else
      set @vNonPhys = '' -- reset 

           -- process layaways, special orders, presales, onholds, and local inventory orders (not sales)
      if @vSaleLineitmTypcode = 'LAYAWAY' or @vSaleLineitmTypcode = 'SPECIAL_ORDER' 
        or @vSaleLineitmTypcode = 'PRESALE' or @vSaleLineitmTypcode = 'ONHOLD' or @vSaleLineitmTypcode = 'LOCALORDER'
        begin
          if (not (@vNonPhys = 'LayawayDeposits' or @vNonPhys = 'LayawayPayments' 
            or @vNonPhys = 'SpOrderDeposits' or @vNonPhys = 'SpOrderPayments' 
            or @vNonPhys = 'OnholdDeposits' or @vNonPhys = 'OnholdPayments' 
            or @vNonPhys = 'LocalInventoryOrderDeposits' or @vNonPhys = 'LocalInventoryOrderPayments' 
            or @vNonPhys = 'PresaleDeposits' or @vNonPhys = 'PresalePayments')) 
            and ((@vLineitemStatcode is null) or (@vLineitemStatcode <> 'CANCEL'))
            begin
            
              set @vNonPhysSaleType = 'SpOrderItems'
              if @vSaleLineitmTypcode = 'LAYAWAY'
                set @vNonPhysSaleType = 'LayawayItems'
              else if @vSaleLineitmTypcode = 'PRESALE'
                set @vNonPhysSaleType = 'PresaleItems'
              else if @vSaleLineitmTypcode = 'ONHOLD'
                set @vNonPhysSaleType = 'OnholdItems'
              else if @vSaleLineitmTypcode = 'LOCALORDER'
                set @vNonPhysSaleType = 'LocalInventoryOrderItems'
              
              -- update flash sales for layaway items
              set @vLayawayPrice = @vUnitPrice * coalesce(@vActualQuantity, 0)
              exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
              @argWrkstnId,@vNonPhys,@vActualQuantity, @vLayawayPrice, @vCurrencyId
            end  
        end
      -- end flash sales update
      -- department sales
      exec sp_ins_upd_merchlvl1_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
      @argWrkstnId,@vDepartmentId,@vQuantity,@vNetAmount,@vGrossAmount,@vCurrencyId      
    end -- sale cursor ends
  close saleCursor
  deallocate saleCursor 
  end -- only when transaction is complete populate flash sales ends

-- update hourly sales
   exec sp_ins_upd_hourly_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
   @argWrkstnId,@vTransTimeStamp,@vTotquantity,@vTotNetAmt,@vTotGrossAmt,@vTransCount,@vCurrencyId 
if @old_context_info is null
	SET CONTEXT_INFO 0x
else
	SET CONTEXT_INFO @old_context_info
GO
-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : SP_REPORT
-- Description       : This procedure is to be executed on the XCenter database to populate the flash report tables.
--                      It calls sp_flash for each record in the trn_trans table where the flash_sales_flag is zero
--                      to generate the data.  All of the report / business logic will be kept in sp_flash.
-- Version           : 19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....         Initial Version
-- PGH 04/25/11		Added the options FAST_FORWARD READ_ONLY to the main cursor to improve performance.
-- BCW 12/05/13		Added optional parameters and logging.
-------------------------------------------------------------------------------------------------------------------
PRINT 'dbo.sp_report';

IF EXISTS (Select * From sysobjects Where name = 'sp_report' and type = 'P')
  DROP PROCEDURE sp_report;
GO

CREATE PROCEDURE sp_report
(
  @job_id     INT     =0,
  @firstLoc_id  INT     =0,
  @lastLoc_id   INT     =999999999,
  @start_date   DATETIME  ='1/1/1900',
  @end_date   DATETIME  ='12/31/9999',
  @batch_count  INT     =-1,
  @nologging    BIT     =0
)
AS
  DECLARE -- Keys
    @vOrganizationId    int,
    @vRetailLocationId  int,
    @vBusinessDate    datetime,
    @vWrkstnId      bigint,
    @vTransSeq      bigint,
    @starttime      DATETIME,
    @sql          VARCHAR(MAX);

set @starttime=GETDATE()

  DECLARE @staging TABLE (
    organization_id  INT       NOT NULL,
    rtl_loc_id       INT       NOT NULL,
    business_date    DATETIME  NOT NULL,
    wkstn_id         BIGINT    NOT NULL,
    trans_seq        BIGINT    NOT NULL
  )

if OBJECT_ID('log_sp_report') IS NULL
  SET @nologging=1

SET @sql = 'SELECT '

if @batch_count > -1
  SET @sql = @sql + ' top(' + cast(@batch_count as varchar(10)) + ') '
SET @sql = @sql + 'trn.organization_id, 
          trn.rtl_loc_id, 
          trn.business_date, 
          trn.wkstn_id, 
          trn.trans_seq
   FROM trn_trans trn with (READPAST)

   LEFT JOIN tsn_tndr_control_trans tndr
    ON trn.organization_id = tndr.organization_id
    AND trn.rtl_loc_id     = tndr.rtl_loc_id
    AND trn.business_date  = tndr.business_date
    AND trn.wkstn_id       = tndr.wkstn_id
    AND trn.trans_seq      = tndr.trans_seq
    AND trn.flash_sales_flag = 0

   WHERE trn.flash_sales_flag = 0
   AND trn.trans_typcode in (''RETAIL_SALE'',''POST_VOID'',''TENDER_CONTROL'')
   AND trn.trans_statcode not like ''CANCEL%''
   AND (tndr.typcode IS NULL OR tndr.typcode IN (''PAID_IN'', ''PAID_OUT''))
   AND (trn.trans_typcode <> ''TENDER_CONTROL'' AND tndr.typcode IS NULL)'

if @firstLoc_id <> 0 OR @lastLoc_id <> 999999999
  SET @sql = @sql + ' AND trn.rtl_loc_id between ' + cast(@firstLoc_id as varchar(10)) + ' AND ' + cast(@lastLoc_id as varchar(10))

if @start_date <> '1/1/1900' OR @end_date <> '12/31/9999'
  SET @sql = @sql + ' AND trn.business_date between ''' + cast(@start_date as varchar(19)) + ''' AND ''' + cast(@end_date as varchar(19)) + ''''

if @nologging = 0
SET @sql = @sql + ' ORDER BY trn.business_date, trn.rtl_loc_id, trn.begin_datetime';

INSERT @staging (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) exec(@sql)

  DECLARE cur_main CURSOR FAST_FORWARD FOR
  SELECT organization_id, 
          rtl_loc_id, 
          business_date, 
          wkstn_id, 
          trans_seq
   FROM @staging

  if @nologging=0
    insert into log_sp_report WITH(ROWLOCK) (job_id,loc_id,business_date,job_start,completed,expected)
    select @job_id, rtl_loc_id, business_date, @starttime, 0, COUNT(*)
    from @staging
    group by rtl_loc_id,business_date

  OPEN cur_main;

  WHILE 1 = 1 BEGIN
    FETCH FROM cur_main 
      INTO @vOrganizationId,
           @vRetailLocationId, 
           @vBusinessDate, 
           @vWrkstnId, 
           @vTransSeq;
  
  IF @@FETCH_STATUS <> 0 
      BREAK;

  if @nologging=0
    update log_sp_report WITH(ROWLOCK) set start_dt = GETDATE() where loc_id = @vRetailLocationId and business_date=@vBusinessDate and job_start=@starttime and job_id=@job_id and start_dt is null

  EXEC sp_flash @vOrganizationId,
          @vRetailLocationId, 
          @vBusinessDate, 
          @vWrkstnId, 
          @vTransSeq;

  if @nologging=0
    update log_sp_report WITH(ROWLOCK) set completed = completed + 1,end_dt = GETDATE() where loc_id = @vRetailLocationId and business_date=@vBusinessDate and job_start=@starttime and job_id=@job_id

  END;
  CLOSE cur_main;
  DEALLOCATE cur_main;

if @nologging=0
  update log_sp_report WITH(ROWLOCK) set job_end = GETDATE() where job_start=@starttime and job_id=@job_id
GO
/* 
 * TRIGGER: [dbo].[trg_insert_trl_returned_item_journal] 
 */

PRINT 'TRIGGER: trg_insert_trl_returned_item_journal';


IF EXISTS (Select * From sysobjects Where name = 'trg_insert_trl_returned_item_journal' and type = 'TR')
  DROP TRIGGER trg_insert_trl_returned_item_journal;
GO

CREATE TRIGGER trg_insert_trl_returned_item_journal
    ON trl_returned_item_journal
    AFTER INSERT
AS
  BEGIN
    DECLARE @new_organization_id int,
            @new_rtl_loc_id int,
            @new_wkstn_id bigint,
            @new_business_date datetime,
            @new_trans_seq bigint,
            @new_rtrans_lineitm_seq int,
            @new_returned_count decimal(11, 2);

    SELECT @new_organization_id = organization_id,
           @new_rtl_loc_id = rtl_loc_id,
           @new_wkstn_id = wkstn_id,
           @new_business_date = business_date,
           @new_trans_seq = trans_seq,    
           @new_rtrans_lineitm_seq = rtrans_lineitm_seq,
           @new_returned_count = returned_count
      FROM inserted;

    IF EXISTS (
        Select 1 From trn_trans trans
          Where trans.organization_id = @new_organization_id
            And trans.rtl_loc_id = @new_rtl_loc_id
            And trans.wkstn_id = @new_wkstn_id
            And trans.business_date = @new_business_date
            And trans.trans_seq = @new_trans_seq) 
    BEGIN
      IF EXISTS (
          Select 1 From trl_returned_item_count With (NOLOCK) 
            Where organization_id = @new_organization_id 
              And rtl_loc_id = @new_rtl_loc_id 
              And wkstn_id = @new_wkstn_id 
              And business_date = @new_business_date 
              And trans_seq = @new_trans_seq 
              And rtrans_lineitm_seq = @new_rtrans_lineitm_seq)
      BEGIN
        UPDATE trl_returned_item_count 
          SET returned_count = returned_count + @new_returned_count
          WHERE organization_id = @new_organization_id 
            AND rtl_loc_id = @new_rtl_loc_id 
            AND wkstn_id = @new_wkstn_id 
            AND business_date = @new_business_date 
            AND trans_seq = @new_trans_seq 
            AND rtrans_lineitm_seq = @new_rtrans_lineitm_seq;
      END
    ELSE
      BEGIN
        INSERT INTO trl_returned_item_count
            (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq, rtrans_lineitm_seq, returned_count)
          VALUES
            (@new_organization_id, @new_rtl_loc_id, @new_wkstn_id, @new_business_date, 
            @new_trans_seq, @new_rtrans_lineitm_seq, @new_returned_count);
      END
    END
  END
GO

INSERT INTO ctl_version_history (
    organization_id, base_schema_version, customer_schema_version, base_schema_date, 
    create_user_id, create_date, update_user_id, update_date)
VALUES (
    $(OrgID), '22.0.0.0.20230127185818', '0.0.0 - 0.0', getDate(), 
    'Oracle', getDate(), 'Oracle', getDate());

GO
