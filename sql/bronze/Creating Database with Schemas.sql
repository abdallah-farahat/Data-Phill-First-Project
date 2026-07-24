Use master;
Go
If Exists(Select 1 From sys.databases where name ='Olist_e_Commerce')
Begin
	Alter Database Olist_e_Commerce Set SINGLE_USER With RollBack Immediate;
	Drop Database Olist_e_Commerce;
End;
Go
Create Database Olist_e_Commerce;
Go
Use Olist_e_Commerce;
Go
Create Schema Bronze;
Go
Create Schema Silver;
Go
Create Schema Gold;
Go

If Not Exists (Select 1 From sys.schemas Where name = 'Audit')
    Exec('Create Schema Audit');
Go

If Object_Id('Audit.ETL_Log','U') Is Not Null
	Drop Table Audit.ETL_Log;

Create Table Audit.ETL_Log(
	Log_Id               Int             Identity(1,1)  Primary Key,
	Batch_Id             Uniqueidentifier               Not Null,
	Source_Batch_Id      Uniqueidentifier               Null,
	Layer_Name           Nvarchar(50)                   Not Null,
	Table_Name           Nvarchar(150)                  Not Null,
	Procedure_Name       Nvarchar(200)                  Null,
	Batch_Start_Time     Datetime2                      Null,
	Batch_End_Time       Datetime2                      Null,
	Batch_Duration_Sec   Int                            Null,
	Load_Start_Time      Datetime2                      Null,
	Load_End_Time        Datetime2                      Null,
	Load_Duration_Sec    Int                            Null,
	Source_Row_Count     Bigint                         Null,
	Rows_Inserted        Bigint                         Null,
	Rows_Updated         Bigint                         Null,
	Rows_Deleted         Bigint                         Null,
	Target_Row_Count     Bigint                         Null,
	Status               Nvarchar(20)                   Not Null
		Constraint CK_ETL_Log_Status
		Check (Status In ('RUNNING','SUCCESS','FAILED','WARNING')),
	Operation_Type       Nvarchar(10)                   Null
		Constraint CK_ETL_Log_Operation
		Check (Operation_Type In ('INSERT','UPDATE','DELETE') Or Operation_Type Is Null),
	Error_Message        Nvarchar(Max)                  Null,
	Error_Number         Int                            Null,
	Error_State          Int                            Null,
	Created_At           Datetime2  Default Sysdatetime()
);
Go