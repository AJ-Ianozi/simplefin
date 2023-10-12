with VSS.Strings;
with VSS.Strings.Conversions;
with Ada.Characters.Conversions;

with Simplefin.Types;
package Simplefin.Utils is
   function To_Wide_Wide_String
      (Item : VSS.Strings.Virtual_String'Class) return Wide_Wide_String
   renames VSS.Strings.Conversions.To_Wide_Wide_String;
   function To_String
      (Item : VSS.Strings.Virtual_String'Class)
   return String is
      (Ada.Characters.Conversions.To_String (To_Wide_Wide_String (Item)));
   procedure Print_Accounts (Items : Simplefin.Types.Account_List);
end Simplefin.Utils;