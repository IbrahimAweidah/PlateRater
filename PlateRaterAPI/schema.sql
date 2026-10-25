-- Run once in the SmarterASP.NET database (Control Panel > Databases > MSSQL > Web SQL Manager).
CREATE TABLE dbo.PlateRaterUsers (
    Id            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PlateRaterUsers PRIMARY KEY,
    GoogleSubject NVARCHAR(255) NOT NULL,
    Email         NVARCHAR(320) NULL,
    Name          NVARCHAR(200) NULL,
    CreatedAt     DATETIME2 NOT NULL,
    CONSTRAINT UQ_PlateRaterUsers_GoogleSubject UNIQUE (GoogleSubject)
);

CREATE TABLE dbo.PlateRaterRatings (
    Id        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PlateRaterRatings PRIMARY KEY,
    Plate     NVARCHAR(10) NOT NULL,
    UserId    INT NOT NULL CONSTRAINT FK_PlateRaterRatings_User REFERENCES dbo.PlateRaterUsers(Id),
    Score     INT NOT NULL CONSTRAINT CK_PlateRaterRatings_Score CHECK (Score BETWEEN 1 AND 5),
    Comment   NVARCHAR(500) NOT NULL,
    CreatedAt DATETIME2 NOT NULL,
    UpdatedAt DATETIME2 NOT NULL,
    CONSTRAINT UQ_PlateRaterRatings_Plate_User UNIQUE (Plate, UserId)
);
