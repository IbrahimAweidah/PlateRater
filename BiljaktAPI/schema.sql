-- The whole Biljakt database, for a fresh, empty database.
-- Run in SmarterASP Control Panel > Databases > MSSQL > Web SQL Manager.
CREATE TABLE dbo.BiljaktUsers (
    Id            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_BiljaktUsers PRIMARY KEY,
    GoogleSubject NVARCHAR(255) NOT NULL,
    Email         NVARCHAR(320) NULL,
    Name          NVARCHAR(200) NULL,
    CreatedAt     DATETIME2 NOT NULL,
    CONSTRAINT UQ_BiljaktUsers_GoogleSubject UNIQUE (GoogleSubject)
);

-- One find per user per plate. Score is an old driver rating, no longer used by the app.
CREATE TABLE dbo.BiljaktRatings (
    Id        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_BiljaktRatings PRIMARY KEY,
    Plate     NVARCHAR(10) NOT NULL,
    UserId    INT NOT NULL CONSTRAINT FK_BiljaktRatings_User REFERENCES dbo.BiljaktUsers(Id),
    Score     INT NULL CONSTRAINT CK_BiljaktRatings_Score CHECK (Score BETWEEN 1 AND 5),
    Comment   NVARCHAR(500) NOT NULL,
    Color     NVARCHAR(20) NULL,
    Kind      NVARCHAR(20) NULL,
    Brand     NVARCHAR(30) NULL,
    CheckStatus     NVARCHAR(10) NULL,
    CheckedByUserId INT NULL,
    CreatedAt DATETIME2 NOT NULL,
    UpdatedAt DATETIME2 NOT NULL,
    CONSTRAINT UQ_BiljaktRatings_Plate_User UNIQUE (Plate, UserId)
);

CREATE TABLE dbo.BiljaktPhotos (
    RatingId    INT NOT NULL CONSTRAINT PK_BiljaktPhotos PRIMARY KEY
                CONSTRAINT FK_BiljaktPhotos_Rating REFERENCES dbo.BiljaktRatings(Id) ON DELETE CASCADE,
    Data        VARBINARY(MAX) NOT NULL,
    ContentType NVARCHAR(50) NOT NULL,
    CheckData   VARBINARY(MAX) NULL,
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
