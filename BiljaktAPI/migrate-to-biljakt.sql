-- Run ONCE in db_a30625_platerater (SmarterASP Control Panel > Databases > MSSQL > Web SQL Manager).
-- 1. Renames the old PlateRater tables and constraints to Biljakt.
-- 2. Makes Score optional (there is no driver rating any more).
-- 3. Adds synonyms with the old names, so the API that is running right now keeps working
--    until the new one is deployed. They can be dropped later.

EXEC sp_rename 'dbo.PlateRaterUsers', 'BiljaktUsers';
EXEC sp_rename 'dbo.PlateRaterRatings', 'BiljaktRatings';
EXEC sp_rename 'dbo.PlateRaterPhotos', 'BiljaktPhotos';
EXEC sp_rename 'dbo.PlateRaterFriendships', 'BiljaktFriendships';

EXEC sp_rename 'dbo.PK_PlateRaterUsers', 'PK_BiljaktUsers', 'OBJECT';
EXEC sp_rename 'dbo.UQ_PlateRaterUsers_GoogleSubject', 'UQ_BiljaktUsers_GoogleSubject', 'OBJECT';
EXEC sp_rename 'dbo.PK_PlateRaterRatings', 'PK_BiljaktRatings', 'OBJECT';
EXEC sp_rename 'dbo.FK_PlateRaterRatings_User', 'FK_BiljaktRatings_User', 'OBJECT';
EXEC sp_rename 'dbo.UQ_PlateRaterRatings_Plate_User', 'UQ_BiljaktRatings_Plate_User', 'OBJECT';
EXEC sp_rename 'dbo.PK_PlateRaterPhotos', 'PK_BiljaktPhotos', 'OBJECT';
EXEC sp_rename 'dbo.FK_PlateRaterPhotos_Rating', 'FK_BiljaktPhotos_Rating', 'OBJECT';
EXEC sp_rename 'dbo.PK_PlateRaterFriendships', 'PK_BiljaktFriendships', 'OBJECT';
EXEC sp_rename 'dbo.FK_PlateRaterFriendships_From', 'FK_BiljaktFriendships_From', 'OBJECT';
EXEC sp_rename 'dbo.FK_PlateRaterFriendships_To', 'FK_BiljaktFriendships_To', 'OBJECT';
EXEC sp_rename 'dbo.DF_PlateRaterFriendships_Accepted', 'DF_BiljaktFriendships_Accepted', 'OBJECT';
EXEC sp_rename 'dbo.UQ_PlateRaterFriendships', 'UQ_BiljaktFriendships', 'OBJECT';
EXEC sp_rename 'dbo.CK_PlateRaterFriendships_NotSelf', 'CK_BiljaktFriendships_NotSelf', 'OBJECT';

-- A column in a CHECK constraint can't be altered, so drop the check, make Score optional, add it back.
ALTER TABLE dbo.BiljaktRatings DROP CONSTRAINT CK_PlateRaterRatings_Score;
ALTER TABLE dbo.BiljaktRatings ALTER COLUMN Score INT NULL;
ALTER TABLE dbo.BiljaktRatings ADD CONSTRAINT CK_BiljaktRatings_Score CHECK (Score BETWEEN 1 AND 5);

CREATE SYNONYM dbo.PlateRaterUsers FOR dbo.BiljaktUsers;
CREATE SYNONYM dbo.PlateRaterRatings FOR dbo.BiljaktRatings;
CREATE SYNONYM dbo.PlateRaterPhotos FOR dbo.BiljaktPhotos;
CREATE SYNONYM dbo.PlateRaterFriendships FOR dbo.BiljaktFriendships;
