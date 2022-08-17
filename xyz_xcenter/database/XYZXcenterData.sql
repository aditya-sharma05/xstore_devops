-- ************************************************************************************************
--
-- This script should contain the customer's initial data load that will become part of the
-- production database image. This file should not contain any store specific data or test data.
--
-- This script runs for all Xcenter install types, after the Xstore data update script runs.
--
-- ************************************************************************************************
DECLARE @intOrganization_ID INT;
SET @intOrganization_ID = $(OrgID);
DECLARE @strCountry_ID VARCHAR(2);
SET @strCountry_ID = $(CountryID);
DECLARE @intStore_ID INT;
SET @intStore_ID = $(StoreID);
DECLARE @strCurrency_ID VARCHAR(3);
SET @strCurrency_ID = $(CurrencyID);


---------------------------------------------------------------------------------------------------
-- Keep this at the end of the file.
