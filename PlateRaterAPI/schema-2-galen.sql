-- Galen update: car color on ratings and private photos.
-- Run once in the SmarterASP.NET database (Control Panel > Databases > MSSQL > Web SQL Manager),
-- BEFORE uploading the new API. The old API keeps working after this runs.
ALTER TABLE dbo.PlateRaterRatings ADD Color NVARCHAR(20) NULL;

CREATE TABLE dbo.PlateRaterPhotos (
    RatingId    INT NOT NULL CONSTRAINT PK_PlateRaterPhotos PRIMARY KEY
                CONSTRAINT FK_PlateRaterPhotos_Rating REFERENCES dbo.PlateRaterRatings(Id) ON DELETE CASCADE,
    Data        VARBINARY(MAX) NOT NULL,
    ContentType NVARCHAR(50) NOT NULL,
    CreatedAt   DATETIME2 NOT NULL
);
