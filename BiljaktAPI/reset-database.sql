-- DELETES ALL DATA. Drops every Biljakt and old PlateRater table, then creates the Biljakt tables empty.
-- Run in db_a30625_platerater (SmarterASP Control Panel > Databases > MSSQL > query editor).

-- Old synonyms, if a migration got half-way.
IF OBJECT_ID('dbo.PlateRaterFriendships', 'SN') IS NOT NULL DROP SYNONYM dbo.PlateRaterFriendships;
IF OBJECT_ID('dbo.PlateRaterPhotos', 'SN') IS NOT NULL DROP SYNONYM dbo.PlateRaterPhotos;
IF OBJECT_ID('dbo.PlateRaterRatings', 'SN') IS NOT NULL DROP SYNONYM dbo.PlateRaterRatings;
IF OBJECT_ID('dbo.PlateRaterUsers', 'SN') IS NOT NULL DROP SYNONYM dbo.PlateRaterUsers;

-- Tables, children first.
IF OBJECT_ID('dbo.PlateRaterFriendships', 'U') IS NOT NULL DROP TABLE dbo.PlateRaterFriendships;
IF OBJECT_ID('dbo.PlateRaterPhotos', 'U') IS NOT NULL DROP TABLE dbo.PlateRaterPhotos;
IF OBJECT_ID('dbo.PlateRaterRatings', 'U') IS NOT NULL DROP TABLE dbo.PlateRaterRatings;
IF OBJECT_ID('dbo.PlateRaterUsers', 'U') IS NOT NULL DROP TABLE dbo.PlateRaterUsers;
IF OBJECT_ID('dbo.BiljaktFriendships', 'U') IS NOT NULL DROP TABLE dbo.BiljaktFriendships;
IF OBJECT_ID('dbo.BiljaktPhotos', 'U') IS NOT NULL DROP TABLE dbo.BiljaktPhotos;
IF OBJECT_ID('dbo.BiljaktRatings', 'U') IS NOT NULL DROP TABLE dbo.BiljaktRatings;
IF OBJECT_ID('dbo.BiljaktUsers', 'U') IS NOT NULL DROP TABLE dbo.BiljaktUsers;

CREATE TABLE dbo.BiljaktUsers (
    Id            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_BiljaktUsers PRIMARY KEY,
    GoogleSubject NVARCHAR(255) NOT NULL,
    Email         NVARCHAR(320) NULL,
    Name          NVARCHAR(200) NULL,
    CreatedAt     DATETIME2 NOT NULL,
    CONSTRAINT UQ_BiljaktUsers_GoogleSubject UNIQUE (GoogleSubject)
);

CREATE TABLE dbo.BiljaktRatings (
    Id        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_BiljaktRatings PRIMARY KEY,
    Plate     NVARCHAR(10) NOT NULL,
    UserId    INT NOT NULL CONSTRAINT FK_BiljaktRatings_User REFERENCES dbo.BiljaktUsers(Id),
    Score     INT NULL CONSTRAINT CK_BiljaktRatings_Score CHECK (Score BETWEEN 1 AND 5),
    Comment   NVARCHAR(500) NOT NULL,
    Color     NVARCHAR(20) NULL,
    Kind      NVARCHAR(20) NULL,
    Brand     NVARCHAR(30) NULL,
    CreatedAt DATETIME2 NOT NULL,
    UpdatedAt DATETIME2 NOT NULL,
    CONSTRAINT UQ_BiljaktRatings_Plate_User UNIQUE (Plate, UserId)
);

CREATE TABLE dbo.BiljaktPhotos (
    RatingId    INT NOT NULL CONSTRAINT PK_BiljaktPhotos PRIMARY KEY
                CONSTRAINT FK_BiljaktPhotos_Rating REFERENCES dbo.BiljaktRatings(Id) ON DELETE CASCADE,
    Data        VARBINARY(MAX) NOT NULL,
    ContentType NVARCHAR(50) NOT NULL,
    CreatedAt   DATETIME2 NOT NULL
);

CREATE TABLE dbo.BiljaktFriendships (
    Id         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_BiljaktFriendships PRIMARY KEY,
    FromUserId INT NOT NULL CONSTRAINT FK_BiljaktFriendships_From REFERENCES dbo.BiljaktUsers(Id),
    ToUserId   INT NOT NULL CONSTRAINT FK_BiljaktFriendships_To REFERENCES dbo.BiljaktUsers(Id),
    Accepted   BIT NOT NULL CONSTRAINT DF_BiljaktFriendships_Accepted DEFAULT 0,
    CreatedAt  DATETIME2 NOT NULL,
    CONSTRAINT UQ_BiljaktFriendships UNIQUE (FromUserId, ToUserId),
    CONSTRAINT CK_BiljaktFriendships_NotSelf CHECK (FromUserId <> ToUserId)
);
