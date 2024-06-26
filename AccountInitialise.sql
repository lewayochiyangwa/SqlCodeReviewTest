USE [GSAMUP]
GO
/****** Object:  StoredProcedure [dbo].[spAccountInitialise]    Script Date: 4/17/2024 12:03:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[spAccountInitialise]
	@ID BIGINT
--WITH ENCRYPTION 
AS
BEGIN

	DECLARE @Name VARCHAR(50);
	DECLARE @AccountNo VARCHAR(50);
	DECLARE @Prefix VARCHAR(50);
	DECLARE @AccountType VARCHAR(50);
	DECLARE @LENGTH INT;

	-- Set the account no length
	SELECT @LENGTH = 10
	-- Get the name of the counterparty
	SELECT	@Name = COALESCE(CASE WHEN a.LifeInsDependentID <> 0 THEN lid.Surname ELSE cp.Name END, mmc.[Name], ag.[Name]),
			@AccountType = act.Name,
			@AccountNo = a.AccountNo
	FROM tblAccount a
	INNER JOIN tblAccountType act ON a.[AccountType] = act.[Type]
	LEFT OUTER JOIN tblCounterparty cp ON cp.[ID] = a.CounterpartyID
	LEFT OUTER JOIN tblMMCounterparty mmc ON mmc.[ID] = a.[MMCounterpartyID]
	LEFT OUTER JOIN tblAgent ag ON ag.[ID] = a.[AgentID]
	LEFT OUTER JOIN tblLifeInsDependent lid ON a.LifeInsDependentID = lid.ID
	WHERE a.[ID] = @ID

	IF ISNULL(@AccountNo , '') = ''
	BEGIN
		IF @Name IS NOT NULL BEGIN
			-- Filter characters
			SET @Name = REPLACE(@Name, ' ', '')
			SET @Name = REPLACE(@Name, '.', '')
			SET @Name = REPLACE(@Name, ',', '')
			SET @Name = REPLACE(@Name, '/', '')
			SET @Name = REPLACE(@Name, '-', '')
		 
			IF @AccountType <> 'Discount buyback'
			-- Create account prefix from Account type and Counterparty name
				SELECT @Prefix = UPPER(SUBSTRING(@AccountType, 1, 1)) + UPPER(SUBSTRING(@Name, 1, 3))
			ELSE
			-- TODO: Find out what the e-thing below is...
				SELECT @Prefix = 'E' + UPPER(SUBSTRING(@Name, 1, 3))

			SET @AccountNo = @Prefix + RIGHT('00000000000' + CAST(@ID AS VARCHAR(10)), @Length - LEN(@Prefix));

			-- Update account with the account no
			UPDATE tblAccount
			SET AccountNo = @AccountNo
			WHERE [ID] = @ID
		END
	END
END;

