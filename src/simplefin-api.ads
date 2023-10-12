with VSS.Strings;
with AWS.URL;
with AWS.Translator;
with Simplefin.Types;
package Simplefin.API is
   --  The API
   --  The connection status for a valid connection.
   type Connection_Status is
      (Unconnected,   --  A connection should not be attempted
       Unauthorized,  --  The credentials are not authorized
       Authenticated, --  The connection is authenticated and active
       Expired,       --  The credentials expired.
       Invalid        --  The access token is invalid or another error occured
      );
   type Connection is tagged private;
   procedure Connect
      (This        : in out Connection;
       Setup_Token : AWS.Translator.Base64_String);
   function Info (This : Connection) return VSS.Strings.Virtual_String;
   function Accounts
      (This : in out Connection)
   return Simplefin.Types.Account_List;
   function Get_Status (This : Connection) return Connection_Status; 

   --  Connect to the simplefin server with provided setup token.
   function Connect
      (Setup_Token : AWS.Translator.Base64_String)
   return Connection;

private
   type Connection is tagged record
      Rest            : AWS.URL.Object;
      Status          : Connection_Status := Unconnected;
      Accounts_Loaded : Boolean := False;
      Accounts        : Simplefin.Types.Account_Set;
   end record;
   procedure Load_Accounts (This : in out Connection);

end Simplefin.API;