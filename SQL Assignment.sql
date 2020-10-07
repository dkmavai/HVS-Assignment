-- Table Script
-- ### ASSUMPTIONS ####
-- 1. Requirement here is just to create a simple table w/o any relational data constraint
-- 2. Apart from primary key (by default clustered indexed), to create indexes, more details/inputs needed to
    -- identify the suitable column(s)

CREATE TABLE [dbo].[Student](
	[Student_Id] [int] IDENTITY(1,1) NOT NULL,
	[Student_Name] [nvarchar](50) NOT NULL,
	[Student_Class] [nvarchar](50)  NULL,	
	[Interests] [nvarchar](50) NULL,
	[Subjects] [nvarchar](50) NULL,	
CONSTRAINT [PK_Student] PRIMARY KEY CLUSTERED 
(
	[Student_Id] ASC
))
GO

-- Make the table audit enabled

-- For auditing, generally, following columns needs to be added on the table

ALTER TABLE [Student]
  ADD Created_By nvarchar(50),
      Created_Date datetime,
      Modified_By nvarchar(50),
      Modified_Date datetime,
      Application_Id nvarchar(50),
      Machine_Id nvarchar(50);
GO

-- Now, to maintain audit trail, a new table Student_Audit with few additional columns needs to be created
-- This table will contain the history records only (records that were either updated or deleted)

CREATE TABLE [dbo].[Student_Audit](
  [Audit_Id] [int] IDENTITY(1,1) NOT NULL,
	[Student_Id] [int] NOT NULL,
	[Student_Name] [nvarchar](50) NOT NULL,
	[Student_Class] [nvarchar](50) NOT NULL,	
	[Interests] [nvarchar](50) NULL,
	[Subjects] [nvarchar](50) NULL,
  [Created_By] [nvarchar](50) NOT NULL,
  [Created_Date] DateTime NOT NULL,
  [Modified_By] [nvarchar](50) NOT NULL,
  [Modified_Date] DateTime NOT NULL,
  [Application_Id] [nvarchar](50) NOT NULL,
  [Machine_Id] [nvarchar](50) NOT NULL,
  [Inserted_At] DateTime Not NULL
CONSTRAINT [PK_Student_Audit] PRIMARY KEY CLUSTERED 
(
	[Audit_Id] ASC
))
GO

--Create a trigger on student table to populte history table (when update or delete operation happens on student table)

CREATE TRIGGER Audit_For_Student ON [Student] 
AFTER UPDATE, DELETE AS
Begin
  Declare @InsertedAt DateTime
  Set @InsertedAt = getDate()

  Insert into [Student_Audit]
    Select  [Student_Id],
	          [Student_Name] ,
	          [Student_Class] ,	
	          [Interests] ,
	          [Subjects],
            [Created_By] ,
            [Created_Date] ,
            [Modified_By] ,
            [Modified_Date] ,
            [Application_Id],
            [Machine_Id] ,
            @InsertedAt
    From Deleted -- Get Records from Magic Table
End

GO
-- Stored procedure to get expiring contracts
-- ### ASSUMPTIONS ####
--  1.  @Depth refers to the no of records to fetch per contract code

CREATE PROCEDURE [dbo].[Get_Expiring_Contracts]
(
    @InputDate DATETIME,
    @Depth INT 
)
AS
BEGIN
	SET NOCOUNT ON

  Select ContractCode, Ticker, LastTrade from
  (
    Select *, ROW_NUMBER() OVER(Partition by ContractCode ORDER BY ContractCode, LastTrade ) AS Depth
    from Contracts Where LastTrade >= @InputDate
  ) C
  Where c.Depth <= @Depth
     
END


