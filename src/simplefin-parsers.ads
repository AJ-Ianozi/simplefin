with VSS.Strings;
with Ada.Streams;
with Simplefin.Types;
with VSS.Stream_Element_Vectors;
package Simplefin.Parsers is

   procedure Parse_Accounts
      (Items   : Ada.Streams.Stream_Element_Array;
       Item    : out Simplefin.Types.Account_Set;
       Success : in out Boolean);

   procedure Parse_Accounts
      (Items   : Wide_Wide_String;
       Item    : out Simplefin.Types.Account_Set;
       Success : in out Boolean);

   procedure Parse_Accounts
      (Items   : VSS.Stream_Element_Vectors.Stream_Element_Vector;
       Item    : out Simplefin.Types.Account_Set;
       Success : in out Boolean);
private

   --  This transiantly stores the account information while parsing
   --  Currency types and custom currency
   type Currency_Type is (Custom_Currency, Standard_Currency);
   type Custom_Currency_Type is record
      Name : VSS.Strings.Virtual_String;
      Abbr : VSS.Strings.Virtual_String;
   end record;
end Simplefin.Parsers;
