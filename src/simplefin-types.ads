pragma Assertion_Policy (Check);
with VSS.Strings;
with VSS.String_Vectors;
with Cashe;
with Cashe.Currency_Handling;
with Cashe.Money_Handling;
with Ada.Calendar;
with ISO.Currencies;
with Ada.Containers.Indefinite_Vectors;
package Simplefin.Types is

   --  Organization
   type Organization is record
      Sfin_Url : VSS.Strings.Virtual_String := VSS.Strings.Empty_Virtual_String;
      Name     : VSS.Strings.Virtual_String := VSS.Strings.Empty_Virtual_String;
      Domain   : VSS.Strings.Virtual_String := VSS.Strings.Empty_Virtual_String;
   end record;

   type Transaction is
   record
      Id          : VSS.Strings.Virtual_String;
      Posted      : Ada.Calendar.Time;
      Amount      : Cashe.Money_Handling.Money;
      Description : VSS.Strings.Virtual_String;
      Payee       : VSS.Strings.Virtual_String;
      Memo        : VSS.Strings.Virtual_String;
      Pending     : Boolean := False;
   end record;

   package Transaction_Vector is new
      Ada.Containers.Indefinite_Vectors
         (Index_Type => Natural, Element_Type => Transaction);
   subtype Transaction_List is Transaction_Vector.Vector;

   type Account is
   record
      Org               : Organization;
      Id                : VSS.Strings.Virtual_String;
      Name              : VSS.Strings.Virtual_String;
      Currency          : Cashe.Currency_Handling.Currency_Data :=
                           (Cashe.Currency_Handling.Type_ISO_Currency,
                            (Key => ISO.Currencies.C_ZZZ));
      Balance           : Cashe.Money_Handling.Money;
      Available_Balance : Cashe.Money_Handling.Money;
      Balance_Date      : Ada.Calendar.Time;
      Transactions      : Transaction_List;
   end record;

   package Account_Vector is new
      Ada.Containers.Indefinite_Vectors
         (Index_Type => Natural, Element_Type => Account);
   subtype Account_List is Account_Vector.Vector;

   type Account_Set is record
      Errors   : VSS.String_Vectors.Virtual_String_Vector;
      Accounts : Account_List;
   end record;

end Simplefin.Types;