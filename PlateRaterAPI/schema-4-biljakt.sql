-- Biljakt update: the driver score is gone, so ratings no longer need one.
-- Run once in db_a30625_platerater (SmarterASP Control Panel > Databases > MSSQL), BEFORE uploading the new API.
-- The existing CHECK (Score BETWEEN 1 AND 5) still allows NULL.
ALTER TABLE dbo.PlateRaterRatings ALTER COLUMN Score INT NULL;
