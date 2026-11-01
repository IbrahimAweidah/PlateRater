-- Galen update: kind and brand of car on ratings, and friends who compete in the hunt.
-- Run once in the SmarterASP.NET database (Control Panel > Databases > MSSQL > Web SQL Manager),
-- AFTER schema-2-galen.sql and BEFORE uploading the new API.
ALTER TABLE dbo.PlateRaterRatings ADD Kind NVARCHAR(20) NULL, Brand NVARCHAR(30) NULL;

CREATE TABLE dbo.PlateRaterFriendships (
    Id         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PlateRaterFriendships PRIMARY KEY,
    FromUserId INT NOT NULL CONSTRAINT FK_PlateRaterFriendships_From REFERENCES dbo.PlateRaterUsers(Id),
    ToUserId   INT NOT NULL CONSTRAINT FK_PlateRaterFriendships_To REFERENCES dbo.PlateRaterUsers(Id),
    Accepted   BIT NOT NULL CONSTRAINT DF_PlateRaterFriendships_Accepted DEFAULT 0,
    CreatedAt  DATETIME2 NOT NULL,
    CONSTRAINT UQ_PlateRaterFriendships UNIQUE (FromUserId, ToUserId),
    CONSTRAINT CK_PlateRaterFriendships_NotSelf CHECK (FromUserId <> ToUserId)
);
