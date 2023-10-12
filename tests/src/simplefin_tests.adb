with Simplefin.Parsers;
with Simplefin.Utils;
with Simplefin.Types;
with Simplefin.API; use Simplefin.API;
with Ada.Text_IO; use Ada.Text_IO;
procedure Simplefin_Tests is
   New_Connection : Simplefin.API.Connection := Connect ("aHR0cHM6Ly9iZXRhLWJyaWRnZS5zaW1wbGVmaW4ub3JnL3NpbXBsZWZpbi9jbGFpbS9ERU1P");
   A : Simplefin.Types.Account_List := New_Connection.Accounts;
begin
   Put_Line (New_Connection.Get_Status'Image);
   Simplefin.Utils.Print_Accounts (A);
end Simplefin_Tests;
