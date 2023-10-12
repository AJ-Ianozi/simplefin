pragma Ada_2022;
with Ada.Text_IO;
with ISO.Currencies;
with Ada.Wide_Wide_Text_IO;
with Ada.Calendar.Formatting;
with Cashe;
with Cashe.Currency_Handling;
package body Simplefin.Utils is

   procedure SPut (S : VSS.Strings.Virtual_String) is
      use Ada.Wide_Wide_Text_IO;
   begin
      Put (To_Wide_Wide_String (S));
   end SPut;

   procedure Print_Accounts (Items : Simplefin.Types.Account_List) is
      use Ada.Text_IO;
      use ISO.Currencies;
      use Ada.Calendar.Formatting;
      use Cashe;
      use Cashe.Currency_Handling;
   begin
      Put_Line ("Accounts Detected: " & Items.Length'Image);
      for X of Items loop
         Put_Line ("____________________________________________________");
         Put      ("Account - """);
         SPut (X.Name);
         Put (""" - """);
         SPut (X.Id);
         Put_Line ("""");
         Put_Line ("├── Org");
         Put      ("│   ├── Sfin_Url: """);
         SPut (X.Org.Sfin_Url);
         Put_Line ("""");
         Put      ("│   ├── Name: """);
         SPut (X.Org.Name);
         Put_Line ("""");
         Put      ("│   └── Domain: """);
         SPut (X.Org.Domain);
         Put_Line ("""");
         Put_Line ("├── Currency");
         case X.Currency.Which_Currency_Type is
            when Type_ISO_Currency =>
               Put      ("│   ├── Currency Code: """);
               Put (X.Currency.ISO_Code.Code);
               Put_Line ("""");
            when Type_Custom_Currency =>
               Put_Line ("│   └── Custom");
               Put      ("│        ├── Name: """);
               Ada.Wide_Wide_Text_IO.Put (X.Currency.Custom_Code.Name);
               Put_Line ("""");
               Put      ("│        └── Abbr: """);
               Ada.Wide_Wide_Text_IO.Put (X.Currency.Custom_Code.Code);
               Put_Line ("""");
         end case;
         Put      ("├── Balance: """);
         Put (X.Balance'Image);
         Put_Line ("""");
         Put      ("├── Balance (av): """);
         Put       (X.Available_Balance'Image);
         Put_Line ("""");
         Put      ("├── Balance (dt): """);
         Put      (Image (X.Balance_Date));
         Put_Line ("""");
         Put_Line ("└── Transactions");
         for T of X.Transactions loop
            Put  ("    ├── Id: """);
            SPut  (T.Id);
            Put_Line ("""");
            Put_Line ("    ├── Posted: """ & Image (T.Posted) & """");
            Put   ("    ├── Amount: """);
            Put   (T.Amount'Image);
            Put_Line ("""");
            Put   ("    ├── Payee: """);
            SPut  (T.Payee);
            Put_Line ("""");
            Put   ("    ├── Memo: """);
            SPut  (T.Memo);
            Put_Line ("""");
            Put   ("    ├── Description: """);
            SPut  (T.Description);
            Put_Line ("""");
            Put_Line   ("    └── Pending: """ & T.Pending'Image & """");
         end loop;
      end loop;
   end Print_Accounts;
end Simplefin.Utils;