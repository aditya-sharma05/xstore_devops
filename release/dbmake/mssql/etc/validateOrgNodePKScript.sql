IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'fn_SplitString') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION [dbo].[fn_SplitString]
GO

CREATE function [dbo].[fn_SplitString]  
    ( 
        @str varchar(8000),  
        @separator char(1) 
    ) 
    returns table 
    AS 
    return ( 
        with tokens(p, a, b) AS ( 
            select  
                1,  
                1,  
                charindex(@separator, @str) 
            union all 
            select 
                p + 1,  
                b + 1,  
                charindex(@separator, @str, b + 1) 
            from tokens 
            where b > 0 
        ) 
        select 
            p IDX, 
            ltrim(rtrim(substring( 
                @str,  
                a,  
                case when b > 0 then b-a ELSE 8000 end)))  
            AS string 
        from tokens 
      ) 
GO

if OBJECT_ID('upgrade_issues') is NULL
CREATE TABLE upgrade_issues (
    table_name	 varchar(50),
    dup_count	 int,
    pk_conflict varchar(max),
    org_code	 varchar(30),
    org_value	 varchar(60),
    rtl_loc_id	 int
)
else
    truncate table upgrade_issues;

IF EXISTS (Select * From sysobjects Where name = 'validate_orgnode_from_pk' and type = 'P')
  DROP PROCEDURE validate_orgnode_from_pk;
GO

CREATE PROCEDURE validate_orgnode_from_pk (
    @tblname AS varchar(255), 
    @newpk AS varchar(255),
    @has_loc AS bit = 0)
AS
BEGIN
declare @sql varchar(max),
	   @col1 varchar(30), @val1 varchar(max),
	   @col2 varchar(30), @val2 varchar(max),
	   @col3 varchar(30), @val3 varchar(max),
	   @col4 varchar(30), @val4 varchar(max),
	   @col5 varchar(30), @val5 varchar(max),
	   @col6 varchar(30), @val6 varchar(max),
	   @col7 varchar(30), @val7 varchar(max),
	   @col8 varchar(30), @val8 varchar(max),
	   @col9 varchar(30), @val9 varchar(max),
	   @colcnt int=0, @crit1 varchar(max),@crit2 varchar(max);

SELECT @colcnt=COUNT(*) from fn_SplitString(@newpk,',');
SELECT @col1=string from fn_SplitString(@newpk,',') where idx=1;
SELECT @col2=string from fn_SplitString(@newpk,',') where idx=2;
if @colcnt>2 SELECT @col3=string from fn_SplitString(@newpk,',') where idx=3;
if @colcnt>3 SELECT @col4=string from fn_SplitString(@newpk,',') where idx=4;
if @colcnt>4 SELECT @col5=string from fn_SplitString(@newpk,',') where idx=5;
if @colcnt>5 SELECT @col6=string from fn_SplitString(@newpk,',') where idx=6;
if @colcnt>6 SELECT @col7=string from fn_SplitString(@newpk,',') where idx=7;
if @colcnt>7 SELECT @col8=string from fn_SplitString(@newpk,',') where idx=8;
if @colcnt>8 SELECT @col9=string from fn_SplitString(@newpk,',') where idx=9;

set @crit1 = @col1 + '='' + cast(i.' + @col1 + ' as varchar(max)) + '' and ' + @col2 + '=''''''+ cast(i.' + @col2 + ' as varchar(max)) + ''''''';
if @colcnt>2 set @crit1 = @crit1 + ' and ' + @col3 + '='''''' + cast(i.' + @col3 + ' as varchar(max)) + ''''''';
if @colcnt>3 set @crit1 = @crit1 + ' and ' + @col4 + '='''''' + cast(i.' + @col4 + ' as varchar(max)) + ''''''';
if @colcnt>4 set @crit1 = @crit1 + ' and ' + @col5 + '='''''' + cast(i.' + @col5 + ' as varchar(max)) + ''''''';
if @colcnt>5 set @crit1 = @crit1 + ' and ' + @col6 + '='''''' + cast(i.' + @col6 + ' as varchar(max)) + ''''''';
if @colcnt>6 set @crit1 = @crit1 + ' and ' + @col7 + '='''''' + cast(i.' + @col7 + ' as varchar(max)) + ''''''';
if @colcnt>7 set @crit1 = @crit1 + ' and ' + @col8 + '='''''' + cast(i.' + @col8 + ' as varchar(max)) + ''''''';
if @colcnt>8 set @crit1 = @crit1 + ' and ' + @col9 + '='''''' + cast(i.' + @col9 + ' as varchar(max)) + ''''''';

set @crit2 = 'i.' + @col1 + ' = a.' + @col1 + ' and i.' + @col2 + ' = a.' + @col2;
if @colcnt>2 set @crit2 = @crit2 + ' and i.' + @col3 + ' = a.' + @col3;
if @colcnt>3 set @crit2 = @crit2 + ' and i.' + @col4 + ' = a.' + @col4;
if @colcnt>4 set @crit2 = @crit2 + ' and i.' + @col5 + ' = a.' + @col5;
if @colcnt>5 set @crit2 = @crit2 + ' and i.' + @col6 + ' = a.' + @col6;
if @colcnt>6 set @crit2 = @crit2 + ' and i.' + @col7 + ' = a.' + @col7;
if @colcnt>7 set @crit2 = @crit2 + ' and i.' + @col8 + ' = a.' + @col8;
if @colcnt>8 set @crit2 = @crit2 + ' and i.' + @col9 + ' = a.' + @col9;

if @has_loc = 0
begin
SET @sql = 'INSERT INTO upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT ''' + @tblname + ''', cnt, ''' + @crit1 + ''', org_code, org_value
from ' + @tblname + ' i
inner join(select ' + @newpk + ', COUNT(*) cnt from ' + @tblname + ' group by ' + @newpk + ' having count(*) > 1) a on ' + @crit2;
end
else
begin
SET @sql = 'INSERT INTO upgrade_issues (table_name,dup_count,pk_conflict,rtl_loc_id)
SELECT ''' + @tblname + ''', cnt, ''' + @crit1 + ''', rtl_loc_id
from ' + @tblname + ' i
inner join(select ' + @newpk + ', COUNT(*) cnt from ' + @tblname + ' group by ' + @newpk + ' having count(*) > 1) a on ' + @crit2;
end

exec(@sql)
END
GO

exec validate_orgnode_from_pk 'itm_item','organization_id, item_id';

exec validate_orgnode_from_pk 'itm_item_cross_reference','organization_id, manufacturer_upc';

exec validate_orgnode_from_pk 'itm_item_dimension','organization_id, item_id';

exec validate_orgnode_from_pk 'itm_item_dimension_type','organization_id, dimension_system, dimension';

exec validate_orgnode_from_pk 'itm_item_dimension_value','organization_id, dimension_system, dimension, value';

exec validate_orgnode_from_pk 'itm_item_label_batch','organization_id, batch_name, item_id, stock_label';

exec validate_orgnode_from_pk 'itm_item_label_properties','organization_id, item_id';

exec validate_orgnode_from_pk 'itm_item_msg','organization_id, msg_id, effective_datetime';

exec validate_orgnode_from_pk 'itm_item_msg_cross_reference','organization_id, item_id, msg_id';

exec validate_orgnode_from_pk 'itm_item_msg_types','organization_id, sale_lineitm_typcode, msg_id';

exec validate_orgnode_from_pk 'itm_item_prompt_properties','organization_id, item_id, property_code';

exec validate_orgnode_from_pk 'itm_item_properties','organization_id, item_id, property_code, effective_date';

exec validate_orgnode_from_pk 'itm_restriction_type','organization_id, restriction_id, restriction_typecode';

exec validate_orgnode_from_pk 'itm_restriction_calendar','organization_id, restriction_id, restriction_typecode, day_code';

exec validate_orgnode_from_pk 'itm_kit_component','organization_id, kit_item_id, component_item_id';

exec validate_orgnode_from_pk 'itm_matrix_sort_order','organization_id, matrix_sort_type, matrix_sort_id';

exec validate_orgnode_from_pk 'itm_merch_hierarchy','organization_id, hierarchy_id';

exec validate_orgnode_from_pk 'itm_non_phys_item','organization_id, item_id';

exec validate_orgnode_from_pk 'itm_refund_schedule','organization_id, item_id, effective_date';

exec validate_orgnode_from_pk 'itm_substitute_items','organization_id, primary_item_id, substitute_item_id';

exec validate_orgnode_from_pk 'itm_vendor','organization_id, vendor_id';

exec validate_orgnode_from_pk 'itm_warranty','organization_id, warranty_typcode, warranty_nbr';

exec validate_orgnode_from_pk 'itm_warranty_item','organization_id, item_id';

exec validate_orgnode_from_pk 'itm_warranty_item_xref','organization_id, item_id, warranty_typcode, warranty_item_id';

exec validate_orgnode_from_pk 'itm_warranty_item_price','organization_id, item_id, warranty_price_seq';

exec validate_orgnode_from_pk 'itm_warranty_journal','organization_id, warranty_typcode, warranty_nbr, journal_seq';

exec validate_orgnode_from_pk 'cat_cust_acct_plan','organization_id, cust_acct_code, plan_id';

exec validate_orgnode_from_pk 'com_address','organization_id, address_id';

exec validate_orgnode_from_pk 'com_code_value','organization_id, category, code';

exec validate_orgnode_from_pk 'com_translations','organization_id, locale, translation_key';

exec validate_orgnode_from_pk 'com_reason_code','organization_id, reason_typcode, reason_code';

exec validate_orgnode_from_pk 'com_receipt_text','organization_id, text_code, text_subcode, text_seq';

exec validate_orgnode_from_pk 'com_report_data','organization_id, owner_type_enum, owner_id, report_id';

exec validate_orgnode_from_pk 'com_report_lookup','organization_id, owner_type_enum, owner_id, report_id';

exec validate_orgnode_from_pk 'com_shipping_cost','organization_id, begin_range, end_range, cost';

exec validate_orgnode_from_pk 'com_shipping_fee','organization_id, rule_name';

exec validate_orgnode_from_pk 'com_shipping_fee_tier','organization_id, rule_name, parent_rule_name';

exec validate_orgnode_from_pk 'com_trans_prompt_properties','organization_id, property_code, effective_date';

exec validate_orgnode_from_pk 'cwo_category_service_loc','organization_id, category_id, service_loc_id';

exec validate_orgnode_from_pk 'cwo_service_loc','organization_id, service_loc_id';

exec validate_orgnode_from_pk 'cwo_task','organization_id, item_id';

exec validate_orgnode_from_pk 'cwo_work_order_category','organization_id, category_id';

exec validate_orgnode_from_pk 'cwo_price_code','organization_id, price_code';

exec validate_orgnode_from_pk 'cwo_work_order_pricing','organization_id, price_code, item_id';

exec validate_orgnode_from_pk 'doc_document','organization_id, document_type, series_id, document_id';

exec validate_orgnode_from_pk 'doc_document_definition','organization_id, series_id, document_type';

exec validate_orgnode_from_pk 'doc_document_def_properties','organization_id, document_type, series_id, doc_seq_nbr';

exec validate_orgnode_from_pk 'doc_document_properties','organization_id, document_id, property_code';

exec validate_orgnode_from_pk 'dsc_coupon_xref','organization_id, coupon_serial_nbr';

exec validate_orgnode_from_pk 'dsc_discount','organization_id, discount_code';

exec validate_orgnode_from_pk 'dsc_discount_compatibility','organization_id, primary_discount_code, compatible_discount_code';

exec validate_orgnode_from_pk 'dsc_discount_group_mapping','organization_id, cust_group_id, discount_code';

exec validate_orgnode_from_pk 'dsc_discount_item_exclusions','organization_id, discount_code, item_id';

exec validate_orgnode_from_pk 'dsc_discount_item_inclusions','organization_id, discount_code, item_id';

exec validate_orgnode_from_pk 'dsc_discount_type_eligibility','organization_id, discount_code, sale_lineitm_typcode';

exec validate_orgnode_from_pk 'hrs_work_codes','organization_id, work_code';

exec validate_orgnode_from_pk 'inv_shipper','organization_id, shipper_id';

exec validate_orgnode_from_pk 'inv_shipper_method','organization_id, shipper_method_id';

exec validate_orgnode_from_pk 'prc_deal','organization_id, deal_id';

exec validate_orgnode_from_pk 'prc_deal_cust_groups','organization_id, deal_id, cust_group_id';

exec validate_orgnode_from_pk 'prc_deal_document_xref','organization_id, deal_id, series_id, document_type';

exec validate_orgnode_from_pk 'prc_deal_field_test','organization_id, deal_id, item_ordinal, item_condition_group, item_condition_seq';

exec validate_orgnode_from_pk 'prc_deal_item','organization_id, deal_id, item_ordinal';

exec validate_orgnode_from_pk 'prc_deal_trig','organization_id, deal_id, deal_trigger';

exec validate_orgnode_from_pk 'prc_deal_week','organization_id, deal_id, day_code, start_time';

exec validate_orgnode_from_pk 'sch_shift','organization_id, shift_id';

exec validate_orgnode_from_pk 'sec_acl','organization_id, secured_object_id';

exec validate_orgnode_from_pk 'sec_groups','organization_id, group_id';

exec validate_orgnode_from_pk 'sec_privilege','organization_id, privilege_type';

exec validate_orgnode_from_pk 'sls_sales_goal','organization_id, sales_goal_id';

exec validate_orgnode_from_pk 'tnd_tndr','organization_id, tndr_id';

exec validate_orgnode_from_pk 'tnd_tndr_availability','organization_id, tndr_id, availability_code';

exec validate_orgnode_from_pk 'tnd_tndr_denomination','organization_id, tndr_id, denomination_id';

exec validate_orgnode_from_pk 'tnd_tndr_user_settings','organization_id, tndr_id, group_id, usage_code, entry_mthd_code';

exec validate_orgnode_from_pk 'hrs_employee_message','organization_id, message_id',1;

IF EXISTS (Select * From sysobjects Where name = 'validate_orgnode_from_pk' and type = 'P')
  DROP PROCEDURE validate_orgnode_from_pk;

IF NOT EXISTS (Select * from upgrade_issues)
BEGIN
    PRINT 'Passed Validation'
    DROP TABLE upgrade_issues;
END
ELSE
BEGIN
    select * from upgrade_issues;
    declare @err nvarchar(max);
    set @err = N'Failed Validation'
    RAISERROR (@err,10,1);
END
GO

