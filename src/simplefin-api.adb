with AWS.Client;
with AWS.Response;
with AWS.Messages;
with Simplefin.Parsers;
with Ada.Text_IO; use Ada.Text_IO;
package body Simplefin.API is

   function Get_Status
      (This : Connection)
   return Connection_Status is (This.Status);

   procedure Connect
      (This        : in out Connection;
       Setup_Token : AWS.Translator.Base64_String)
   is
      use AWS.URL;
      use AWS.Translator;
      --  Decode the claim URL that we'll be loading.
      Claim_URL : constant Object := Parse (URL => Base64_Decode (Setup_Token),
                                            Check_Validity => False);
   begin
      --  The status will be unconnected at start.
      This.Status := Unconnected;
      --  Verify that this is a valid URL and it is using HTTPS
      if Is_Valid (Claim_URL) and then Security (Claim_URL) then
         declare
            use AWS.Client;
            use AWS.Messages;
            use AWS.Response;
            --  This will hold our HTTP response.
            Result : constant Data := Post (URL => URL (Claim_URL),
                                            Data => "");
         begin
put_line ("Connecting to " & URL (Claim_URL));
            case AWS.Response.Status_Code (Result) is
               when S200 =>
                  This.Rest := Parse (URL => Message_Body (Result),
                                          Check_Validity => False);
                  if Is_Valid (This.Rest) and then
                     Security (This.Rest) and then
                     User (This.Rest)'Length /= 0 and then
                     Password (This.Rest)'Length /= 0
                  then
                     This.Status := Authenticated;
                  end if;
               when S403 =>
                  This.Status := Unauthorized;
               when others =>
                  This.Status := Invalid;
            end case;
         end;
      end if;
      if This.Status = Unconnected then
         --  Something must have went wrong.
         This.Status := Invalid;
      end if;
   end Connect;

   procedure Load_Accounts (This : in out Connection) is
   begin
      This.Accounts_Loaded := False;
      if This.Status = Authenticated then
         declare
            use AWS.URL;
            use AWS.Client;
            use AWS.Messages;
            use AWS.Response;
            use Simplefin.Types;
            Request_URL : constant String := URL (This.Rest) & "/accounts";
            Result  : constant Data := Get (URL => Request_URL,
                                            User => User (This.Rest),
                                            Pwd => Password (This.Rest),
                                            Follow_Redirection => True);
         begin
   put_line ("Connecting to " & Request_URL);


            case AWS.Response.Status_Code (Result) is
               when S200 =>
                  declare
                     use Simplefin.Parsers;
                     use VSS.Strings;
                     Success : Boolean := True;
                     New_Set : Account_Set;
                  begin
                     Parse_Accounts (Message_Body (Result), New_Set, Success);
                     if Success then
                        This.Accounts := New_Set;
                        This.Accounts_Loaded := True;
                        if (for some X of This.Accounts.Errors =>
                             X.Starts_With ("You must reauthenticate"))
                        then
                           This.Status := Expired;
                        end if;
                     else
                        This.Accounts.Errors.Clear;
                        This.Accounts.Errors.Append ("Bad JSON");
                     end if;

                  end;

               when S403 =>
                  This.Status := Unauthorized;
               when others =>
                  This.Status := Invalid;
            end case;
         end;
      end if;
   end Load_Accounts;

   function Accounts
      (This : in out Connection)
   return Simplefin.Types.Account_List is
   begin
      if not This.Accounts_Loaded then
         Load_Accounts (This);
      end if;
      return This.Accounts.Accounts;
   end Accounts;
   function Info
      (This : Connection)
   return VSS.Strings.Virtual_String is
   begin
      return "";
   end Info;

   --  Connect to the simplefin server with provided setup token.
   function Connect (Setup_Token : AWS.Translator.Base64_String)
   return Connection is
      Result : Connection;
   begin
      Result.Connect (Setup_Token);
      return Result;
   end Connect;

end Simplefin.API;