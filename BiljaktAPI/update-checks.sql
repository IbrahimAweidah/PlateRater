-- Friend checks (2026-11-01). Run once in db_a30625_platerater, BEFORE the new API is deployed.
-- Keeps all data. Adds the columns for "a friend checks finds where the photo doesn't match".
ALTER TABLE dbo.BiljaktRatings ADD CheckStatus NVARCHAR(10) NULL, CheckedByUserId INT NULL;
ALTER TABLE dbo.BiljaktPhotos ADD CheckData VARBINARY(MAX) NULL;
