pragma Ada_2022;
with AWS.Client;
with VSS.Strings; use VSS.Strings;
with AWS.Messages;
with AWS.Response;
with ISO.Currencies;
with Cashe.Money_Handling;
with Cashe.Currency_Handling;
with VSS.JSON.Pull_Readers;
with VSS.Strings.Conversions;
with Ada.Calendar;
with Ada.Calendar.Conversions;
with Interfaces.C;
with Ada.Characters.Conversions;
with VSS.JSON.Pull_Readers.Simple;
with VSS.Strings.Converters;
with VSS.Strings.Converters.Encoders;
with VSS.String_Vectors;
with VSS.Text_Streams.Memory_UTF8_Input;
with VSS.Stream_Element_Vectors.Conversions;

package body Simplefin.Parsers is
   procedure Read_Decimal
      (Src  : VSS.Strings.Virtual_String;
       Item    : out Cashe.Decimal;
       Success : in out Boolean);
   procedure Read_ISO_Cur (Src     : VSS.Strings.Virtual_String;
                   Item    : out ISO.Currencies.Currency;
                   Success : in out Boolean);
   procedure Read_Custom_Cur (Src     : VSS.Strings.Virtual_String;
                   Item    : out Custom_Currency_Type;
                   Success : in out Boolean);
   procedure Read_Org
         (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
          Item    : out Simplefin.Types.Organization;
          Success : in out Boolean);
   procedure Read_Transaction
         (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
          Item    : out Simplefin.Types.Transaction;
          Cur     : Cashe.Currency_Handling.Currency_Data;
          Success : in out Boolean);
   procedure Read_Transaction_List
         (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
          Item    : out Simplefin.Types.Transaction_List;
          Cur     : Cashe.Currency_Handling.Currency_Data;
          Success : in out Boolean);
   procedure Read_Account
      (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
       Item    : out Simplefin.Types.Account;
       Success : in out Boolean);
   procedure Read_Account_List
         (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
         Item    : out Simplefin.Types.Account_List;
         Success : in out Boolean);
   procedure Read_String_List
         (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
          Item    : out VSS.String_Vectors.Virtual_String_Vector;
          Success : in out Boolean);
   procedure Read_Account_Set
      (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
       Item    : out Simplefin.Types.Account_Set;
       Success : in out Boolean);
   procedure Parse_Custom_Currency
      (Items : Ada.Streams.Stream_Element_Array;
       Cur   : out Custom_Currency_Type;
       Success : in out Boolean);
   procedure Skip_Object
      (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class);

   procedure Skip_Object
      (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class) is
   begin
      loop
         case Reader.Read_Next is
            when VSS.JSON.Pull_Readers.End_Object =>
               exit;
            when others =>
               null;
         end case;
      end loop;
   end Skip_Object;

   procedure Read_Decimal
      (Src  : VSS.Strings.Virtual_String;
       Item    : out Cashe.Decimal;
       Success : in out Boolean)
   is
   begin
      declare
         use Cashe;
         use VSS.Strings.Conversions;
         Temp_String : constant Wide_Wide_String := To_Wide_Wide_String (Src);
      begin
         Item := Decimal'Wide_Wide_Value (Temp_String);
      end;
   exception
      --  Ahahaahaha
      when Constraint_Error =>
         Success := False;
   end Read_Decimal;

   procedure Read_ISO_Cur (Src     : VSS.Strings.Virtual_String;
                   Item    : out ISO.Currencies.Currency;
                   Success : in out Boolean)
   is
      use ISO.Currencies;
      use VSS.Strings.Conversions;
      Test_Key : constant Wide_Wide_String := To_Wide_Wide_String (Src);
   begin
      if Test_Key'Length = 3 then
         declare
            Prefix : constant Wide_Wide_String := "C_";
         begin
            Item := (Key => Currency_Key'Wide_Wide_Value (Prefix & Test_Key));
         end;
      else
         Success := False;
      end if;
   exception
      when Constraint_Error =>
         Success := False;
   end Read_ISO_Cur;

   procedure Read_Custom_Cur (Src     : VSS.Strings.Virtual_String;
                   Item    : out Custom_Currency_Type;
                   Success : in out Boolean)
   is
      use VSS.Strings.Conversions;
      use Ada.Characters.Conversions;

      Test_Key : constant String := To_String (To_Wide_Wide_String (Src));
   begin
      declare
         use AWS.Client;
         use AWS.Messages;
         use AWS.Response;
         Message_Data : constant Data := Get (URL => Test_Key);
      begin
         case AWS.Response.Status_Code (Message_Data) is
            when S200 =>
               Parse_Custom_Currency
                  (Message_Body (Message_Data), Item, Success);
            when others =>
               Success := False;
         end case;
      end;
   exception
      when others =>
         Success := False;
   end Read_Custom_Cur;
   procedure Read_Org
      (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
       Item    : out Simplefin.Types.Organization;
       Success : in out Boolean) is
   begin
      while Success loop
         case Reader.Read_Next is
            --  Start of the next account object
            when VSS.JSON.Pull_Readers.Key_Name =>
               if Reader.Key_Name = "domain" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        Item.Domain := Reader.String_Value;

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "name" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        Item.Name := Reader.String_Value;

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "sfin-url" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        Item.Sfin_Url := Reader.String_Value;

                     when others =>
                        Success := False;
                  end case;

               else
                  Success := False;
               end if;

            when VSS.JSON.Pull_Readers.Start_Object =>
               null;

            when VSS.JSON.Pull_Readers.End_Object =>
               exit;

            when others =>
               Success := False;
         end case;
      end loop;
   end Read_Org;
   procedure Read_Transaction
      (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
       Item    : out Simplefin.Types.Transaction;
       Cur     : Cashe.Currency_Handling.Currency_Data;
       Success : in out Boolean) is
   begin
      while Success loop
         case Reader.Read_Next is
            --  Start of the next account object
            when VSS.JSON.Pull_Readers.Key_Name =>
               if Reader.Key_Name = "id" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        Item.Id := Reader.String_Value;

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "posted" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.Number_Value =>
                        Item.Posted :=
                           Ada.Calendar.Conversions.To_Ada_Time
                              (Interfaces.C.long
                                 (VSS.JSON.As_Integer (Reader.Number_Value)));

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "amount" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        declare
                           use Cashe;
                           use Cashe.Money_Handling;
                           D : Decimal;
                        begin
                           Read_Decimal (Reader.String_Value, D, Success);
                           if Success then
                              Item.Amount := From_Major (D, Cur);
                           end if;
                        end;

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "description" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        Item.Description := Reader.String_Value;

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "memo" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        Item.Memo := Reader.String_Value;

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "payee" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        Item.Payee := Reader.String_Value;

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "pending" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.Boolean_Value =>
                        Item.Pending := Reader.Boolean_Value;

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "extra" then
                  --  Todo
                  Skip_Object (Reader);

               else
                  Success := False;
               end if;

            when VSS.JSON.Pull_Readers.Start_Object =>
               null;

            when VSS.JSON.Pull_Readers.End_Object =>
               exit;

            when others =>
               Success := False;
         end case;
      end loop;
   end Read_Transaction;
   procedure Read_Transaction_List
      (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
       Item    : out Simplefin.Types.Transaction_List;
       Cur     : Cashe.Currency_Handling.Currency_Data;
       Success : in out Boolean) is
   begin
      while Success loop
         case Reader.Read_Next is
            --  Start of the next account object
            when VSS.JSON.Pull_Readers.Start_Object =>
               declare
                  Next_Transaction : Simplefin.Types.Transaction;
               begin
                  Read_Transaction (Reader, Next_Transaction, Cur, Success);
                  Item.Append (Next_Transaction);
               end;

            when VSS.JSON.Pull_Readers.Start_Array =>
               null;

            when VSS.JSON.Pull_Readers.End_Array =>
               exit;

            when others =>
               Success := False;
         end case;
      end loop;
   end Read_Transaction_List;
   procedure Read_Account
      (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
       Item    : out Simplefin.Types.Account;
       Success : in out Boolean)
   is
      --  Confirming that we have currency already set.
      Currency_Is_Set : Boolean := False;
   begin
      while Success loop
         case Reader.Read_Next is
            --  Start of the next account object
            when VSS.JSON.Pull_Readers.Key_Name =>
               if Reader.Key_Name = "org" then
                  Read_Org (Reader, Item.Org, Success);

               elsif Reader.Key_Name = "id" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        Item.Id := Reader.String_Value;

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "name" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        Item.Name := Reader.String_Value;

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "currency" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        declare
                           use Cashe.Currency_Handling;
                           Cur_Success       : Boolean := True;
                           Temp_ISO_Currency : ISO.Currencies.Currency;
                        begin
                           Read_ISO_Cur (Reader.String_Value,
                                          Temp_ISO_Currency,
                                          Cur_Success);
                           if Cur_Success then
                              Item.Currency := (Type_ISO_Currency,
                                                Temp_ISO_Currency);
                           else
                              declare
                                 use VSS.Strings.Conversions;
                                 Temp_Custom_Currency : Custom_Currency_Type;
                              begin
                                 Read_Custom_Cur (Reader.String_Value,
                                       Temp_Custom_Currency,
                                       Success);
                                 if Success then
                                    Item.Currency :=
                                       (Type_Custom_Currency,
                                        Create
                                         (Code => To_Wide_Wide_String
                                            (Temp_Custom_Currency.Abbr),
                                          Name => To_Wide_Wide_String
                                            (Temp_Custom_Currency.Name)));
                                 end if;
                              end;
                           end if;
                           Currency_Is_Set := True;
                        end;

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "balance" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        if Currency_Is_Set then
                           declare
                              use Cashe;
                              use Cashe.Money_Handling;
                              D : Decimal;
                           begin
                              Read_Decimal (Reader.String_Value, D, Success);
                              if Success then
                                 Item.Balance := From_Major (D, Item.Currency);
                              end if;
                           end;
                        else
                           Success := False;
                        end if;
                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "available-balance" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        if Currency_Is_Set then
                           declare
                              use Cashe;
                              use Cashe.Money_Handling;
                              D : Decimal;
                           begin
                              Read_Decimal (Reader.String_Value, D, Success);
                              if Success then
                                 Item.Available_Balance :=
                                    From_Major (D, Item.Currency);
                              end if;
                           end;
                        else
                           Success := False;
                        end if;

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "balance-date" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.Number_Value =>
                        Item.Balance_Date :=
                           Ada.Calendar.Conversions.To_Ada_Time
                              (Interfaces.C.long
                                 (VSS.JSON.As_Integer (Reader.Number_Value)));

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "transactions" then
                  Read_Transaction_List
                     (Reader, Item.Transactions, Item.Currency, Success);

               elsif Reader.Key_Name = "extra" then
                  --  Todo
                  Skip_Object (Reader);

               else
                  Success := False;
               end if;

            when VSS.JSON.Pull_Readers.Start_Object =>
               null;

            when VSS.JSON.Pull_Readers.End_Object =>
               exit;

            when others =>
               Success := False;
         end case;
      end loop;
   end Read_Account;

   procedure Read_Account_List
      (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
       Item    : out Simplefin.Types.Account_List;
       Success : in out Boolean) is
   begin
      while Success loop
         case Reader.Read_Next is
            --  Start of the next account object
            when VSS.JSON.Pull_Readers.Start_Object =>
               declare
                  Next_Account : Simplefin.Types.Account;
               begin
                  Read_Account (Reader, Next_Account, Success);
                  if Success then
                     Item.Append (Next_Account);
                  end if;
               end;

            when VSS.JSON.Pull_Readers.Start_Array =>
               null;

            when VSS.JSON.Pull_Readers.End_Array =>
               exit;

            when others =>
               Success := False;
         end case;
      end loop;
   end Read_Account_List;

   procedure Read_String_List
      (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
       Item    : out VSS.String_Vectors.Virtual_String_Vector;
       Success : in out Boolean) is
   begin
      while Success loop
         case Reader.Read_Next is
            when VSS.JSON.Pull_Readers.String_Value =>
               Item.Append (Reader.String_Value);

            when VSS.JSON.Pull_Readers.Start_Array =>
               null;

            when VSS.JSON.Pull_Readers.End_Array =>
               exit;

            when others =>
               Success := False;
         end case;
      end loop;
   end Read_String_List;
   procedure Read_Account_Set
      (Reader  : in out VSS.JSON.Pull_Readers.JSON_Pull_Reader'Class;
       Item    : out Simplefin.Types.Account_Set;
       Success : in out Boolean) is
   begin
      while Success loop
         case Reader.Read_Next is
            when VSS.JSON.Pull_Readers.Key_Name =>
               if Reader.Key_Name = "errors" then
                  Read_String_List (Reader, Item.Errors, Success);

               elsif Reader.Key_Name = "accounts" then
                  Read_Account_List (Reader, Item.Accounts, Success);
               else
                  Success := False;
               end if;

            when VSS.JSON.Pull_Readers.Start_Object =>
               null;

            when VSS.JSON.Pull_Readers.End_Object =>
               exit;

            when others =>
               Success := False;
         end case;
      end loop;
   end Read_Account_Set;

   procedure Parse_Custom_Currency
      (Items : Ada.Streams.Stream_Element_Array;
       Cur   : out Custom_Currency_Type;
       Success : in out Boolean)
   is
      use VSS.Stream_Element_Vectors.Conversions;
      use type VSS.JSON.Pull_Readers.JSON_Event_Kind;
      Stream  : aliased
                  VSS.Text_Streams.Memory_UTF8_Input.Memory_UTF8_Input_Stream;
      Reader  : VSS.JSON.Pull_Readers.Simple.JSON_Simple_Pull_Reader;
   begin
      Stream.Set_Data (To_Stream_Element_Vector (Items));
      Reader.Set_Stream (Stream'Unchecked_Access);
      if Reader.Read_Next /= VSS.JSON.Pull_Readers.Start_Document then
         Success := False;
      end if;

      while Success loop
         case Reader.Read_Next is
            when VSS.JSON.Pull_Readers.Key_Name =>
               if Reader.Key_Name = "name" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        Cur.Name := Reader.String_Value;

                     when others =>
                        Success := False;
                  end case;

               elsif Reader.Key_Name = "abbr" then
                  case Reader.Read_Next is
                     when VSS.JSON.Pull_Readers.String_Value =>
                        Cur.Abbr := Reader.String_Value;

                     when others =>
                        Success := False;
                  end case;
               else
                  Success := False;
               end if;

            when VSS.JSON.Pull_Readers.Start_Object =>
               null;

            when VSS.JSON.Pull_Readers.End_Object =>
               exit;

            when others =>
               Success := False;
         end case;
      end loop;

      if Success and then
         Reader.Read_Next /= VSS.JSON.Pull_Readers.End_Document
      then
         Success := False;
      end if;

   end Parse_Custom_Currency;

   procedure Parse_Accounts
      (Items   : VSS.Stream_Element_Vectors.Stream_Element_Vector;
       Item    : out Simplefin.Types.Account_Set;
       Success : in out Boolean)
   is
      use type VSS.JSON.Pull_Readers.JSON_Event_Kind;
      Stream : aliased
                  VSS.Text_Streams.Memory_UTF8_Input.Memory_UTF8_Input_Stream;
      Reader : VSS.JSON.Pull_Readers.Simple.JSON_Simple_Pull_Reader;
   begin
      Stream.Set_Data (Items);
      Reader.Set_Stream (Stream'Unchecked_Access);
      if Reader.Read_Next /= VSS.JSON.Pull_Readers.Start_Document then
         Success := False;
      end if;
      Read_Account_Set (Reader, Item, Success);

      if Success and then
         Reader.Read_Next /= VSS.JSON.Pull_Readers.End_Document
      then
         Success := False;
      end if;

   end Parse_Accounts;

   procedure Parse_Accounts
      (Items   : Ada.Streams.Stream_Element_Array;
       Item    : out Simplefin.Types.Account_Set;
       Success : in out Boolean)
   is
      use VSS.Stream_Element_Vectors;
      use VSS.Stream_Element_Vectors.Conversions;
      Stream : constant Stream_Element_Vector :=
                  To_Stream_Element_Vector (Items);
   begin
      Parse_Accounts (Stream, Item, Success);
   end Parse_Accounts;

   procedure Parse_Accounts
      (Items   : Wide_Wide_String;
       Item    : out Simplefin.Types.Account_Set;
       Success : in out Boolean)
   is
      use VSS.Strings.Converters;
      use VSS.Stream_Element_Vectors;
      use VSS.Strings.Converters.Encoders;
      Encoder : Virtual_String_Encoder;
   begin
      Encoder.Initialize ("utf-8", [Stateless => True, others => False]);
      declare
         Stream : constant Stream_Element_Vector :=
                     Encoder.Encode (To_Virtual_String (Items));
      begin
         Parse_Accounts (Stream, Item, Success);
      end;
   end Parse_Accounts;

end Simplefin.Parsers;