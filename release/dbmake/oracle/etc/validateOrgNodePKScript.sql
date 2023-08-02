SET SERVEROUTPUT ON SIZE 10000

SPOOL validate.log;

begin
  IF SP_TABLE_EXISTS ('dtv','upgrade_issues') THEN
     EXECUTE IMMEDIATE 'delete from dtv.upgrade_issues';
    commit;
  ELSE
    EXECUTE IMMEDIATE 'CREATE TABLE dtv.upgrade_issues (
    table_name	 varchar2(128),
    dup_count	 number(10,0),
    pk_conflict varchar2(4000),
    org_code	 varchar2(30),
    org_value	 varchar2(60),
    rtl_loc_id	 number(10,0))';
  end if;
end;
/

INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_item', cnt,  'organization_id=' || i.organization_id || ' and item_id=''' || i.item_id ||'''', org_code,org_value
from itm_item i
inner join(select organization_id, item_id,COUNT(*) cnt from dtv.itm_item group by organization_id, item_id having count(*) > 1) a on i.organization_id= a.organization_id and i.item_id= a.item_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_item_cross_reference', cnt,  'organization_id=' || i.organization_id || ' and manufacturer_upc=''' || i.manufacturer_upc ||'''', org_code,org_value
from itm_item_cross_reference i
inner join(select organization_id, manufacturer_upc,COUNT(*) cnt from dtv.itm_item_cross_reference group by organization_id, manufacturer_upc having count(*) > 1) a on i.organization_id= a.organization_id and i.manufacturer_upc= a.manufacturer_upc;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_item_dimension', cnt,  'organization_id=' || i.organization_id || ' and item_id=''' || i.item_id ||'''', org_code,org_value
from itm_item_dimension i
inner join(select organization_id, item_id,COUNT(*) cnt from dtv.itm_item_dimension group by organization_id, item_id having count(*) > 1) a on i.organization_id= a.organization_id and i.item_id= a.item_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_item_dimension_type', cnt,  'organization_id=' || i.organization_id || ' and dimension_system=''' || i.dimension_system ||''' and dimension=''' || i.dimension ||'''', org_code,org_value
from itm_item_dimension_type i
inner join(select organization_id, dimension_system, dimension,COUNT(*) cnt from dtv.itm_item_dimension_type group by organization_id, dimension_system, dimension having count(*) > 1) a on i.organization_id= a.organization_id and i.dimension_system= a.dimension_system and i.dimension= a.dimension;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_item_dimension_value', cnt,  'organization_id=' || i.organization_id || ' and dimension_system=''' || i.dimension_system ||''' and dimension=''' || i.dimension ||''' and value=''' || i.value ||'''', org_code,org_value
from itm_item_dimension_value i
inner join(select organization_id, dimension_system, dimension, value,COUNT(*) cnt from dtv.itm_item_dimension_value group by organization_id, dimension_system, dimension, value having count(*) > 1) a on i.organization_id= a.organization_id and i.dimension_system= a.dimension_system and i.dimension= a.dimension and i.value= a.value;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_item_label_batch', cnt,  'organization_id=' || i.organization_id || ' and batch_name=''' || i.batch_name ||''' and item_id=''' || i.item_id ||''' and stock_label=''' || i.stock_label ||'''', org_code,org_value
from itm_item_label_batch i
inner join(select organization_id, batch_name, item_id, stock_label,COUNT(*) cnt from dtv.itm_item_label_batch group by organization_id, batch_name, item_id, stock_label having count(*) > 1) a on i.organization_id= a.organization_id and i.batch_name= a.batch_name and i.item_id= a.item_id and i.stock_label= a.stock_label;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_item_label_properties', cnt,  'organization_id=' || i.organization_id || ' and item_id=''' || i.item_id ||'''', org_code,org_value
from itm_item_label_properties i
inner join(select organization_id, item_id,COUNT(*) cnt from dtv.itm_item_label_properties group by organization_id, item_id having count(*) > 1) a on i.organization_id= a.organization_id and i.item_id= a.item_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_item_msg', cnt,  'organization_id=' || i.organization_id || ' and msg_id=''' || i.msg_id ||''' and effective_datetime=''' || i.effective_datetime ||'''', org_code,org_value
from itm_item_msg i
inner join(select organization_id, msg_id, effective_datetime,COUNT(*) cnt from dtv.itm_item_msg group by organization_id, msg_id, effective_datetime having count(*) > 1) a on i.organization_id= a.organization_id and i.msg_id= a.msg_id and i.effective_datetime= a.effective_datetime;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_item_msg_cross_reference', cnt,  'organization_id=' || i.organization_id || ' and item_id=''' || i.item_id ||''' and msg_id=''' || i.msg_id ||'''', org_code,org_value
from itm_item_msg_cross_reference i
inner join(select organization_id, item_id, msg_id,COUNT(*) cnt from dtv.itm_item_msg_cross_reference group by organization_id, item_id, msg_id having count(*) > 1) a on i.organization_id= a.organization_id and i.item_id= a.item_id and i.msg_id= a.msg_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_item_msg_types', cnt,  'organization_id=' || i.organization_id || ' and sale_lineitm_typcode=''' || i.sale_lineitm_typcode ||''' and msg_id=''' || i.msg_id ||'''', org_code,org_value
from itm_item_msg_types i
inner join(select organization_id, sale_lineitm_typcode, msg_id,COUNT(*) cnt from dtv.itm_item_msg_types group by organization_id, sale_lineitm_typcode, msg_id having count(*) > 1) a on i.organization_id= a.organization_id and i.sale_lineitm_typcode= a.sale_lineitm_typcode and i.msg_id= a.msg_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_item_prompt_properties', cnt,  'organization_id=' || i.organization_id || ' and item_id=''' || i.item_id ||''' and property_code=''' || i.property_code ||'''', org_code,org_value
from itm_item_prompt_properties i
inner join(select organization_id, item_id, property_code,COUNT(*) cnt from dtv.itm_item_prompt_properties group by organization_id, item_id, property_code having count(*) > 1) a on i.organization_id= a.organization_id and i.item_id= a.item_id and i.property_code= a.property_code;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_item_properties', cnt,  'organization_id=' || i.organization_id || ' and item_id=''' || i.item_id ||''' and property_code=''' || i.property_code ||''' and effective_date=''' || i.effective_date ||'''', org_code,org_value
from itm_item_properties i
inner join(select organization_id, item_id, property_code, effective_date,COUNT(*) cnt from dtv.itm_item_properties group by organization_id, item_id, property_code, effective_date having count(*) > 1) a on i.organization_id= a.organization_id and i.item_id= a.item_id and i.property_code= a.property_code and i.effective_date= a.effective_date;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_restriction_type', cnt,  'organization_id=' || i.organization_id || ' and restriction_id=''' || i.restriction_id ||''' and restriction_typecode=''' || i.restriction_typecode ||'''', org_code,org_value
from itm_restriction_type i
inner join(select organization_id, restriction_id, restriction_typecode,COUNT(*) cnt from dtv.itm_restriction_type group by organization_id, restriction_id, restriction_typecode having count(*) > 1) a on i.organization_id= a.organization_id and i.restriction_id= a.restriction_id and i.restriction_typecode= a.restriction_typecode;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_restriction_calendar', cnt,  'organization_id=' || i.organization_id || ' and restriction_id=''' || i.restriction_id ||''' and restriction_typecode=''' || i.restriction_typecode ||''' and day_code=''' || i.day_code ||'''', org_code,org_value
from itm_restriction_calendar i
inner join(select organization_id, restriction_id, restriction_typecode, day_code,COUNT(*) cnt from dtv.itm_restriction_calendar group by organization_id, restriction_id, restriction_typecode, day_code having count(*) > 1) a on i.organization_id= a.organization_id and i.restriction_id= a.restriction_id and i.restriction_typecode= a.restriction_typecode and i.day_code= a.day_code;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_kit_component', cnt,  'organization_id=' || i.organization_id || ' and kit_item_id=''' || i.kit_item_id ||''' and component_item_id=''' || i.component_item_id ||'''', org_code,org_value
from itm_kit_component i
inner join(select organization_id, kit_item_id, component_item_id,COUNT(*) cnt from dtv.itm_kit_component group by organization_id, kit_item_id, component_item_id having count(*) > 1) a on i.organization_id= a.organization_id and i.kit_item_id= a.kit_item_id and i.component_item_id= a.component_item_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_matrix_sort_order', cnt,  'organization_id=' || i.organization_id || ' and matrix_sort_type=''' || i.matrix_sort_type ||''' and matrix_sort_id=''' || i.matrix_sort_id ||'''', org_code,org_value
from itm_matrix_sort_order i
inner join(select organization_id, matrix_sort_type, matrix_sort_id,COUNT(*) cnt from dtv.itm_matrix_sort_order group by organization_id, matrix_sort_type, matrix_sort_id having count(*) > 1) a on i.organization_id= a.organization_id and i.matrix_sort_type= a.matrix_sort_type and i.matrix_sort_id= a.matrix_sort_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_merch_hierarchy', cnt,  'organization_id=' || i.organization_id || ' and hierarchy_id=''' || i.hierarchy_id ||'''', org_code,org_value
from itm_merch_hierarchy i
inner join(select organization_id, hierarchy_id,COUNT(*) cnt from dtv.itm_merch_hierarchy group by organization_id, hierarchy_id having count(*) > 1) a on i.organization_id= a.organization_id and i.hierarchy_id= a.hierarchy_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_non_phys_item', cnt,  'organization_id=' || i.organization_id || ' and item_id=''' || i.item_id ||'''', org_code,org_value
from itm_non_phys_item i
inner join(select organization_id, item_id,COUNT(*) cnt from dtv.itm_non_phys_item group by organization_id, item_id having count(*) > 1) a on i.organization_id= a.organization_id and i.item_id= a.item_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_refund_schedule', cnt,  'organization_id=' || i.organization_id || ' and item_id=''' || i.item_id ||''' and effective_date=''' || i.effective_date ||'''', org_code,org_value
from itm_refund_schedule i
inner join(select organization_id, item_id, effective_date,COUNT(*) cnt from dtv.itm_refund_schedule group by organization_id, item_id, effective_date having count(*) > 1) a on i.organization_id= a.organization_id and i.item_id= a.item_id and i.effective_date= a.effective_date;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_substitute_items', cnt,  'organization_id=' || i.organization_id || ' and primary_item_id=''' || i.primary_item_id ||''' and substitute_item_id=''' || i.substitute_item_id ||'''', org_code,org_value
from itm_substitute_items i
inner join(select organization_id, primary_item_id, substitute_item_id,COUNT(*) cnt from dtv.itm_substitute_items group by organization_id, primary_item_id, substitute_item_id having count(*) > 1) a on i.organization_id= a.organization_id and i.primary_item_id= a.primary_item_id and i.substitute_item_id= a.substitute_item_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_vendor', cnt,  'organization_id=' || i.organization_id || ' and vendor_id=''' || i.vendor_id ||'''', org_code,org_value
from itm_vendor i
inner join(select organization_id, vendor_id,COUNT(*) cnt from dtv.itm_vendor group by organization_id, vendor_id having count(*) > 1) a on i.organization_id= a.organization_id and i.vendor_id= a.vendor_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_warranty', cnt,  'organization_id=' || i.organization_id || ' and warranty_typcode=''' || i.warranty_typcode ||''' and warranty_nbr=''' || i.warranty_nbr ||'''', org_code,org_value
from itm_warranty i
inner join(select organization_id, warranty_typcode, warranty_nbr,COUNT(*) cnt from dtv.itm_warranty group by organization_id, warranty_typcode, warranty_nbr having count(*) > 1) a on i.organization_id= a.organization_id and i.warranty_typcode= a.warranty_typcode and i.warranty_nbr= a.warranty_nbr;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_warranty_item', cnt,  'organization_id=' || i.organization_id || ' and item_id=''' || i.item_id ||'''', org_code,org_value
from itm_warranty_item i
inner join(select organization_id, item_id,COUNT(*) cnt from dtv.itm_warranty_item group by organization_id, item_id having count(*) > 1) a on i.organization_id= a.organization_id and i.item_id= a.item_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_warranty_item_xref', cnt,  'organization_id=' || i.organization_id || ' and item_id=''' || i.item_id ||''' and warranty_typcode=''' || i.warranty_typcode ||''' and warranty_item_id=''' || i.warranty_item_id ||'''', org_code,org_value
from itm_warranty_item_xref i
inner join(select organization_id, item_id, warranty_typcode, warranty_item_id,COUNT(*) cnt from dtv.itm_warranty_item_xref group by organization_id, item_id, warranty_typcode, warranty_item_id having count(*) > 1) a on i.organization_id= a.organization_id and i.item_id= a.item_id and i.warranty_typcode= a.warranty_typcode and i.warranty_item_id= a.warranty_item_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_warranty_item_price', cnt,  'organization_id=' || i.organization_id || ' and item_id=''' || i.item_id ||''' and warranty_price_seq=''' || i.warranty_price_seq ||'''', org_code,org_value
from itm_warranty_item_price i
inner join(select organization_id, item_id, warranty_price_seq,COUNT(*) cnt from dtv.itm_warranty_item_price group by organization_id, item_id, warranty_price_seq having count(*) > 1) a on i.organization_id= a.organization_id and i.item_id= a.item_id and i.warranty_price_seq= a.warranty_price_seq;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'itm_warranty_journal', cnt,  'organization_id=' || i.organization_id || ' and warranty_typcode=''' || i.warranty_typcode ||''' and warranty_nbr=''' || i.warranty_nbr ||''' and journal_seq=''' || i.journal_seq ||'''', org_code,org_value
from itm_warranty_journal i
inner join(select organization_id, warranty_typcode, warranty_nbr, journal_seq,COUNT(*) cnt from dtv.itm_warranty_journal group by organization_id, warranty_typcode, warranty_nbr, journal_seq having count(*) > 1) a on i.organization_id= a.organization_id and i.warranty_typcode= a.warranty_typcode and i.warranty_nbr= a.warranty_nbr and i.journal_seq= a.journal_seq;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'cat_cust_acct_plan', cnt,  'organization_id=' || i.organization_id || ' and cust_acct_code=''' || i.cust_acct_code ||''' and plan_id=''' || i.plan_id ||'''', org_code,org_value
from cat_cust_acct_plan i
inner join(select organization_id, cust_acct_code, plan_id,COUNT(*) cnt from dtv.cat_cust_acct_plan group by organization_id, cust_acct_code, plan_id having count(*) > 1) a on i.organization_id= a.organization_id and i.cust_acct_code= a.cust_acct_code and i.plan_id= a.plan_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'com_address', cnt,  'organization_id=' || i.organization_id || ' and address_id=''' || i.address_id ||'''', org_code,org_value
from com_address i
inner join(select organization_id, address_id,COUNT(*) cnt from dtv.com_address group by organization_id, address_id having count(*) > 1) a on i.organization_id= a.organization_id and i.address_id= a.address_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'com_code_value', cnt,  'organization_id=' || i.organization_id || ' and category=''' || i.category ||''' and code=''' || i.code ||'''', org_code,org_value
from com_code_value i
inner join(select organization_id, category, code,COUNT(*) cnt from dtv.com_code_value group by organization_id, category, code having count(*) > 1) a on i.organization_id= a.organization_id and i.category= a.category and i.code= a.code;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'com_translations', cnt,  'organization_id=' || i.organization_id || ' and locale=''' || i.locale ||''' and translation_key=''' || i.translation_key ||'''', org_code,org_value
from com_translations i
inner join(select organization_id, locale, translation_key,COUNT(*) cnt from dtv.com_translations group by organization_id, locale, translation_key having count(*) > 1) a on i.organization_id= a.organization_id and i.locale= a.locale and i.translation_key= a.translation_key;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'com_reason_code', cnt,  'organization_id=' || i.organization_id || ' and reason_typcode=''' || i.reason_typcode ||''' and reason_code=''' || i.reason_code ||'''', org_code,org_value
from com_reason_code i
inner join(select organization_id, reason_typcode, reason_code,COUNT(*) cnt from dtv.com_reason_code group by organization_id, reason_typcode, reason_code having count(*) > 1) a on i.organization_id= a.organization_id and i.reason_typcode= a.reason_typcode and i.reason_code= a.reason_code;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'com_receipt_text', cnt,  'organization_id=' || i.organization_id || ' and text_code=''' || i.text_code ||''' and text_subcode=''' || i.text_subcode ||''' and text_seq=''' || i.text_seq ||'''', org_code,org_value
from com_receipt_text i
inner join(select organization_id, text_code, text_subcode, text_seq,COUNT(*) cnt from dtv.com_receipt_text group by organization_id, text_code, text_subcode, text_seq having count(*) > 1) a on i.organization_id= a.organization_id and i.text_code= a.text_code and i.text_subcode= a.text_subcode and i.text_seq= a.text_seq;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'com_report_data', cnt,  'organization_id=' || i.organization_id || ' and owner_type_enum=''' || i.owner_type_enum ||''' and owner_id=''' || i.owner_id ||''' and report_id=''' || i.report_id ||'''', org_code,org_value
from com_report_data i
inner join(select organization_id, owner_type_enum, owner_id, report_id,COUNT(*) cnt from dtv.com_report_data group by organization_id, owner_type_enum, owner_id, report_id having count(*) > 1) a on i.organization_id= a.organization_id and i.owner_type_enum= a.owner_type_enum and i.owner_id= a.owner_id and i.report_id= a.report_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'com_report_lookup', cnt,  'organization_id=' || i.organization_id || ' and owner_type_enum=''' || i.owner_type_enum ||''' and owner_id=''' || i.owner_id ||''' and report_id=''' || i.report_id ||'''', org_code,org_value
from com_report_lookup i
inner join(select organization_id, owner_type_enum, owner_id, report_id,COUNT(*) cnt from dtv.com_report_lookup group by organization_id, owner_type_enum, owner_id, report_id having count(*) > 1) a on i.organization_id= a.organization_id and i.owner_type_enum= a.owner_type_enum and i.owner_id= a.owner_id and i.report_id= a.report_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'com_shipping_cost', cnt,  'organization_id=' || i.organization_id || ' and begin_range=''' || i.begin_range ||''' and end_range=''' || i.end_range ||''' and cost=''' || i.cost ||'''', org_code,org_value
from com_shipping_cost i
inner join(select organization_id, begin_range, end_range, cost,COUNT(*) cnt from dtv.com_shipping_cost group by organization_id, begin_range, end_range, cost having count(*) > 1) a on i.organization_id= a.organization_id and i.begin_range= a.begin_range and i.end_range= a.end_range and i.cost= a.cost;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'com_shipping_fee', cnt,  'organization_id=' || i.organization_id || ' and rule_name=''' || i.rule_name ||'''', org_code,org_value
from com_shipping_fee i
inner join(select organization_id, rule_name,COUNT(*) cnt from dtv.com_shipping_fee group by organization_id, rule_name having count(*) > 1) a on i.organization_id= a.organization_id and i.rule_name= a.rule_name;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'com_shipping_fee_tier', cnt,  'organization_id=' || i.organization_id || ' and rule_name=''' || i.rule_name ||''' and parent_rule_name=''' || i.parent_rule_name ||'''', org_code,org_value
from com_shipping_fee_tier i
inner join(select organization_id, rule_name, parent_rule_name,COUNT(*) cnt from dtv.com_shipping_fee_tier group by organization_id, rule_name, parent_rule_name having count(*) > 1) a on i.organization_id= a.organization_id and i.rule_name= a.rule_name and i.parent_rule_name= a.parent_rule_name;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'com_trans_prompt_properties', cnt,  'organization_id=' || i.organization_id || ' and property_code=''' || i.property_code ||''' and effective_date=''' || i.effective_date ||'''', org_code,org_value
from com_trans_prompt_properties i
inner join(select organization_id, property_code, effective_date,COUNT(*) cnt from dtv.com_trans_prompt_properties group by organization_id, property_code, effective_date having count(*) > 1) a on i.organization_id= a.organization_id and i.property_code= a.property_code and i.effective_date= a.effective_date;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'cwo_category_service_loc', cnt,  'organization_id=' || i.organization_id || ' and category_id=''' || i.category_id ||''' and service_loc_id=''' || i.service_loc_id ||'''', org_code,org_value
from cwo_category_service_loc i
inner join(select organization_id, category_id, service_loc_id,COUNT(*) cnt from dtv.cwo_category_service_loc group by organization_id, category_id, service_loc_id having count(*) > 1) a on i.organization_id= a.organization_id and i.category_id= a.category_id and i.service_loc_id= a.service_loc_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'cwo_service_loc', cnt,  'organization_id=' || i.organization_id || ' and service_loc_id=''' || i.service_loc_id ||'''', org_code,org_value
from cwo_service_loc i
inner join(select organization_id, service_loc_id,COUNT(*) cnt from dtv.cwo_service_loc group by organization_id, service_loc_id having count(*) > 1) a on i.organization_id= a.organization_id and i.service_loc_id= a.service_loc_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'cwo_task', cnt,  'organization_id=' || i.organization_id || ' and item_id=''' || i.item_id ||'''', org_code,org_value
from cwo_task i
inner join(select organization_id, item_id,COUNT(*) cnt from dtv.cwo_task group by organization_id, item_id having count(*) > 1) a on i.organization_id= a.organization_id and i.item_id= a.item_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'cwo_work_order_category', cnt,  'organization_id=' || i.organization_id || ' and category_id=''' || i.category_id ||'''', org_code,org_value
from cwo_work_order_category i
inner join(select organization_id, category_id,COUNT(*) cnt from dtv.cwo_work_order_category group by organization_id, category_id having count(*) > 1) a on i.organization_id= a.organization_id and i.category_id= a.category_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'cwo_price_code', cnt,  'organization_id=' || i.organization_id || ' and price_code=''' || i.price_code ||'''', org_code,org_value
from cwo_price_code i
inner join(select organization_id, price_code,COUNT(*) cnt from dtv.cwo_price_code group by organization_id, price_code having count(*) > 1) a on i.organization_id= a.organization_id and i.price_code= a.price_code;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'cwo_work_order_pricing', cnt,  'organization_id=' || i.organization_id || ' and price_code=''' || i.price_code ||''' and item_id=''' || i.item_id ||'''', org_code,org_value
from cwo_work_order_pricing i
inner join(select organization_id, price_code, item_id,COUNT(*) cnt from dtv.cwo_work_order_pricing group by organization_id, price_code, item_id having count(*) > 1) a on i.organization_id= a.organization_id and i.price_code= a.price_code and i.item_id= a.item_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'doc_document', cnt,  'organization_id=' || i.organization_id || ' and document_type=''' || i.document_type ||''' and series_id=''' || i.series_id ||''' and document_id=''' || i.document_id ||'''', org_code,org_value
from doc_document i
inner join(select organization_id, document_type, series_id, document_id,COUNT(*) cnt from dtv.doc_document group by organization_id, document_type, series_id, document_id having count(*) > 1) a on i.organization_id= a.organization_id and i.document_type= a.document_type and i.series_id= a.series_id and i.document_id= a.document_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'doc_document_definition', cnt,  'organization_id=' || i.organization_id || ' and series_id=''' || i.series_id ||''' and document_type=''' || i.document_type ||'''', org_code,org_value
from doc_document_definition i
inner join(select organization_id, series_id, document_type,COUNT(*) cnt from dtv.doc_document_definition group by organization_id, series_id, document_type having count(*) > 1) a on i.organization_id= a.organization_id and i.series_id= a.series_id and i.document_type= a.document_type;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'doc_document_def_properties', cnt,  'organization_id=' || i.organization_id || ' and document_type=''' || i.document_type ||''' and series_id=''' || i.series_id ||''' and doc_seq_nbr=''' || i.doc_seq_nbr ||'''', org_code,org_value
from doc_document_def_properties i
inner join(select organization_id, document_type, series_id, doc_seq_nbr,COUNT(*) cnt from dtv.doc_document_def_properties group by organization_id, document_type, series_id, doc_seq_nbr having count(*) > 1) a on i.organization_id= a.organization_id and i.document_type= a.document_type and i.series_id= a.series_id and i.doc_seq_nbr= a.doc_seq_nbr;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'doc_document_properties', cnt,  'organization_id=' || i.organization_id || ' and document_id=''' || i.document_id ||''' and property_code=''' || i.property_code ||'''', org_code,org_value
from doc_document_properties i
inner join(select organization_id, document_id, property_code,COUNT(*) cnt from dtv.doc_document_properties group by organization_id, document_id, property_code having count(*) > 1) a on i.organization_id= a.organization_id and i.document_id= a.document_id and i.property_code= a.property_code;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'dsc_coupon_xref', cnt,  'organization_id=' || i.organization_id || ' and coupon_serial_nbr=''' || i.coupon_serial_nbr ||'''', org_code,org_value
from dsc_coupon_xref i
inner join(select organization_id, coupon_serial_nbr,COUNT(*) cnt from dtv.dsc_coupon_xref group by organization_id, coupon_serial_nbr having count(*) > 1) a on i.organization_id= a.organization_id and i.coupon_serial_nbr= a.coupon_serial_nbr;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'dsc_discount', cnt,  'organization_id=' || i.organization_id || ' and discount_code=''' || i.discount_code ||'''', org_code,org_value
from dsc_discount i
inner join(select organization_id, discount_code,COUNT(*) cnt from dtv.dsc_discount group by organization_id, discount_code having count(*) > 1) a on i.organization_id= a.organization_id and i.discount_code= a.discount_code;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'dsc_discount_compatibility', cnt,  'organization_id=' || i.organization_id || ' and primary_discount_code=''' || i.primary_discount_code ||''' and compatible_discount_code=''' || i.compatible_discount_code ||'''', org_code,org_value
from dsc_discount_compatibility i
inner join(select organization_id, primary_discount_code, compatible_discount_code,COUNT(*) cnt from dtv.dsc_discount_compatibility group by organization_id, primary_discount_code, compatible_discount_code having count(*) > 1) a on i.organization_id= a.organization_id and i.primary_discount_code= a.primary_discount_code and i.compatible_discount_code= a.compatible_discount_code;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'dsc_discount_group_mapping', cnt,  'organization_id=' || i.organization_id || ' and cust_group_id=''' || i.cust_group_id ||''' and discount_code=''' || i.discount_code ||'''', org_code,org_value
from dsc_discount_group_mapping i
inner join(select organization_id, cust_group_id, discount_code,COUNT(*) cnt from dtv.dsc_discount_group_mapping group by organization_id, cust_group_id, discount_code having count(*) > 1) a on i.organization_id= a.organization_id and i.cust_group_id= a.cust_group_id and i.discount_code= a.discount_code;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'dsc_discount_item_exclusions', cnt,  'organization_id=' || i.organization_id || ' and discount_code=''' || i.discount_code ||''' and item_id=''' || i.item_id ||'''', org_code,org_value
from dsc_discount_item_exclusions i
inner join(select organization_id, discount_code, item_id,COUNT(*) cnt from dtv.dsc_discount_item_exclusions group by organization_id, discount_code, item_id having count(*) > 1) a on i.organization_id= a.organization_id and i.discount_code= a.discount_code and i.item_id= a.item_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'dsc_discount_item_inclusions', cnt,  'organization_id=' || i.organization_id || ' and discount_code=''' || i.discount_code ||''' and item_id=''' || i.item_id ||'''', org_code,org_value
from dsc_discount_item_inclusions i
inner join(select organization_id, discount_code, item_id,COUNT(*) cnt from dtv.dsc_discount_item_inclusions group by organization_id, discount_code, item_id having count(*) > 1) a on i.organization_id= a.organization_id and i.discount_code= a.discount_code and i.item_id= a.item_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'dsc_discount_type_eligibility', cnt,  'organization_id=' || i.organization_id || ' and discount_code=''' || i.discount_code ||''' and sale_lineitm_typcode=''' || i.sale_lineitm_typcode ||'''', org_code,org_value
from dsc_discount_type_eligibility i
inner join(select organization_id, discount_code, sale_lineitm_typcode,COUNT(*) cnt from dtv.dsc_discount_type_eligibility group by organization_id, discount_code, sale_lineitm_typcode having count(*) > 1) a on i.organization_id= a.organization_id and i.discount_code= a.discount_code and i.sale_lineitm_typcode= a.sale_lineitm_typcode;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'hrs_work_codes', cnt,  'organization_id=' || i.organization_id || ' and work_code=''' || i.work_code ||'''', org_code,org_value
from hrs_work_codes i
inner join(select organization_id, work_code,COUNT(*) cnt from dtv.hrs_work_codes group by organization_id, work_code having count(*) > 1) a on i.organization_id= a.organization_id and i.work_code= a.work_code;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'inv_shipper', cnt,  'organization_id=' || i.organization_id || ' and shipper_id=''' || i.shipper_id ||'''', org_code,org_value
from inv_shipper i
inner join(select organization_id, shipper_id,COUNT(*) cnt from dtv.inv_shipper group by organization_id, shipper_id having count(*) > 1) a on i.organization_id= a.organization_id and i.shipper_id= a.shipper_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'inv_shipper_method', cnt,  'organization_id=' || i.organization_id || ' and shipper_method_id=''' || i.shipper_method_id ||'''', org_code,org_value
from inv_shipper_method i
inner join(select organization_id, shipper_method_id,COUNT(*) cnt from dtv.inv_shipper_method group by organization_id, shipper_method_id having count(*) > 1) a on i.organization_id= a.organization_id and i.shipper_method_id= a.shipper_method_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'prc_deal', cnt,  'organization_id=' || i.organization_id || ' and deal_id=''' || i.deal_id ||'''', org_code,org_value
from prc_deal i
inner join(select organization_id, deal_id,COUNT(*) cnt from dtv.prc_deal group by organization_id, deal_id having count(*) > 1) a on i.organization_id= a.organization_id and i.deal_id= a.deal_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'prc_deal_cust_groups', cnt,  'organization_id=' || i.organization_id || ' and deal_id=''' || i.deal_id ||''' and cust_group_id=''' || i.cust_group_id ||'''', org_code,org_value
from prc_deal_cust_groups i
inner join(select organization_id, deal_id, cust_group_id,COUNT(*) cnt from dtv.prc_deal_cust_groups group by organization_id, deal_id, cust_group_id having count(*) > 1) a on i.organization_id= a.organization_id and i.deal_id= a.deal_id and i.cust_group_id= a.cust_group_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'prc_deal_document_xref', cnt,  'organization_id=' || i.organization_id || ' and deal_id=''' || i.deal_id ||''' and series_id=''' || i.series_id ||''' and document_type=''' || i.document_type ||'''', org_code,org_value
from prc_deal_document_xref i
inner join(select organization_id, deal_id, series_id, document_type,COUNT(*) cnt from dtv.prc_deal_document_xref group by organization_id, deal_id, series_id, document_type having count(*) > 1) a on i.organization_id= a.organization_id and i.deal_id= a.deal_id and i.series_id= a.series_id and i.document_type= a.document_type;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'prc_deal_field_test', cnt,  'organization_id=' || i.organization_id || ' and deal_id=''' || i.deal_id ||''' and item_ordinal=''' || i.item_ordinal ||''' and item_condition_group=''' || i.item_condition_group ||''' and item_condition_seq=''' || i.item_condition_seq ||'''', org_code,org_value
from prc_deal_field_test i
inner join(select organization_id, deal_id, item_ordinal, item_condition_group, item_condition_seq,COUNT(*) cnt from dtv.prc_deal_field_test group by organization_id, deal_id, item_ordinal, item_condition_group, item_condition_seq having count(*) > 1) a on i.organization_id= a.organization_id and i.deal_id= a.deal_id and i.item_ordinal= a.item_ordinal and i.item_condition_group= a.item_condition_group and i.item_condition_seq= a.item_condition_seq;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'prc_deal_item', cnt,  'organization_id=' || i.organization_id || ' and deal_id=''' || i.deal_id ||''' and item_ordinal=''' || i.item_ordinal ||'''', org_code,org_value
from prc_deal_item i
inner join(select organization_id, deal_id, item_ordinal,COUNT(*) cnt from dtv.prc_deal_item group by organization_id, deal_id, item_ordinal having count(*) > 1) a on i.organization_id= a.organization_id and i.deal_id= a.deal_id and i.item_ordinal= a.item_ordinal;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'prc_deal_trig', cnt,  'organization_id=' || i.organization_id || ' and deal_id=''' || i.deal_id ||''' and deal_trigger=''' || i.deal_trigger ||'''', org_code,org_value
from prc_deal_trig i
inner join(select organization_id, deal_id, deal_trigger,COUNT(*) cnt from dtv.prc_deal_trig group by organization_id, deal_id, deal_trigger having count(*) > 1) a on i.organization_id= a.organization_id and i.deal_id= a.deal_id and i.deal_trigger= a.deal_trigger;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'prc_deal_week', cnt,  'organization_id=' || i.organization_id || ' and deal_id=''' || i.deal_id ||''' and day_code=''' || i.day_code ||''' and start_time=''' || i.start_time ||'''', org_code,org_value
from prc_deal_week i
inner join(select organization_id, deal_id, day_code, start_time,COUNT(*) cnt from dtv.prc_deal_week group by organization_id, deal_id, day_code, start_time having count(*) > 1) a on i.organization_id= a.organization_id and i.deal_id= a.deal_id and i.day_code= a.day_code and i.start_time= a.start_time;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'sch_shift', cnt,  'organization_id=' || i.organization_id || ' and shift_id=''' || i.shift_id ||'''', org_code,org_value
from sch_shift i
inner join(select organization_id, shift_id,COUNT(*) cnt from dtv.sch_shift group by organization_id, shift_id having count(*) > 1) a on i.organization_id= a.organization_id and i.shift_id= a.shift_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'sec_acl', cnt,  'organization_id=' || i.organization_id || ' and secured_object_id=''' || i.secured_object_id ||'''', org_code,org_value
from sec_acl i
inner join(select organization_id, secured_object_id,COUNT(*) cnt from dtv.sec_acl group by organization_id, secured_object_id having count(*) > 1) a on i.organization_id= a.organization_id and i.secured_object_id= a.secured_object_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'sec_groups', cnt,  'organization_id=' || i.organization_id || ' and group_id=''' || i.group_id ||'''', org_code,org_value
from sec_groups i
inner join(select organization_id, group_id,COUNT(*) cnt from dtv.sec_groups group by organization_id, group_id having count(*) > 1) a on i.organization_id= a.organization_id and i.group_id= a.group_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'sec_privilege', cnt,  'organization_id=' || i.organization_id || ' and privilege_type=''' || i.privilege_type ||'''', org_code,org_value
from sec_privilege i
inner join(select organization_id, privilege_type,COUNT(*) cnt from dtv.sec_privilege group by organization_id, privilege_type having count(*) > 1) a on i.organization_id= a.organization_id and i.privilege_type= a.privilege_type;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'sls_sales_goal', cnt,  'organization_id=' || i.organization_id || ' and sales_goal_id=''' || i.sales_goal_id ||'''', org_code,org_value
from sls_sales_goal i
inner join(select organization_id, sales_goal_id,COUNT(*) cnt from dtv.sls_sales_goal group by organization_id, sales_goal_id having count(*) > 1) a on i.organization_id= a.organization_id and i.sales_goal_id= a.sales_goal_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'tnd_tndr', cnt,  'organization_id=' || i.organization_id || ' and tndr_id=''' || i.tndr_id ||'''', org_code,org_value
from tnd_tndr i
inner join(select organization_id, tndr_id,COUNT(*) cnt from dtv.tnd_tndr group by organization_id, tndr_id having count(*) > 1) a on i.organization_id= a.organization_id and i.tndr_id= a.tndr_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'tnd_tndr_availability', cnt,  'organization_id=' || i.organization_id || ' and tndr_id=''' || i.tndr_id ||''' and availability_code=''' || i.availability_code ||'''', org_code,org_value
from tnd_tndr_availability i
inner join(select organization_id, tndr_id, availability_code,COUNT(*) cnt from dtv.tnd_tndr_availability group by organization_id, tndr_id, availability_code having count(*) > 1) a on i.organization_id= a.organization_id and i.tndr_id= a.tndr_id and i.availability_code= a.availability_code;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'tnd_tndr_denomination', cnt,  'organization_id=' || i.organization_id || ' and tndr_id=''' || i.tndr_id ||''' and denomination_id=''' || i.denomination_id ||'''', org_code,org_value
from tnd_tndr_denomination i
inner join(select organization_id, tndr_id, denomination_id,COUNT(*) cnt from dtv.tnd_tndr_denomination group by organization_id, tndr_id, denomination_id having count(*) > 1) a on i.organization_id= a.organization_id and i.tndr_id= a.tndr_id and i.denomination_id= a.denomination_id;
 
INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,org_code,org_value)
SELECT 'tnd_tndr_user_settings', cnt,  'organization_id=' || i.organization_id || ' and tndr_id=''' || i.tndr_id ||''' and group_id=''' || i.group_id ||''' and usage_code=''' || i.usage_code ||''' and entry_mthd_code=''' || i.entry_mthd_code ||'''', org_code,org_value
from tnd_tndr_user_settings i
inner join(select organization_id, tndr_id, group_id, usage_code, entry_mthd_code,COUNT(*) cnt from dtv.tnd_tndr_user_settings group by organization_id, tndr_id, group_id, usage_code, entry_mthd_code having count(*) > 1) a on i.organization_id= a.organization_id and i.tndr_id= a.tndr_id and i.group_id= a.group_id and i.usage_code= a.usage_code and i.entry_mthd_code= a.entry_mthd_code;

INSERT INTO DTV.upgrade_issues (table_name,dup_count,pk_conflict,rtl_loc_id)
SELECT 'hrs_employee_message', cnt,  'organization_id=' || i.organization_id || ' and message_id=''' || i.message_id ||'''', rtl_loc_id
from hrs_employee_message i
inner join(select organization_id, message_id,COUNT(*) cnt from dtv.hrs_employee_message group by organization_id, message_id having count(*) > 1) a on i.organization_id= a.organization_id and i.message_id= a.message_id;
commit;

select * from dtv.upgrade_issues;

declare
testcnt int;
begin
select count(*) into testcnt from dtv.upgrade_issues;
if testcnt>0 then
    RAISE_APPLICATION_ERROR(-20000, 'Failed Validation');
else
    dbms_output.put_line('Passed Validation');
    EXECUTE IMMEDIATE 'DROP TABLE dtv.upgrade_issues';
end if;
end;
/

SPOOL OFF;