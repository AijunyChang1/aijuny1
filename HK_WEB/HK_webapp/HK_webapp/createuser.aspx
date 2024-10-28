<%@ Page Language="C#" MasterPageFile="~/NavMaster.master" AutoEventWireup="true" CodeBehind="createuser.aspx.cs" Inherits="HK_webapp.createuser" %>

<asp:Content ID="Content_createuser" ContentPlaceHolderID="RightContent" runat="Server">

    <br/>
    <br/>
    <asp:ScriptManager ID="ScriptManager1" runat="server"></asp:ScriptManager>

    <table  border="0" align="center" cellpadding="0"cellspacing="0" id="Table1">
        <tr>
            <td> 
               <strong><font color="blue" size="5">创建新用户</font></strong>
               <br/>
               <br/>
               <div id="NewUser" align="center" style="background-color:#DDDDDD;width:400px;">
                  <table style="width:100%;text-align:center;" border="0">
                  <tr><td>&nbsp</td></tr>
                  <tr>
                      <td style="text-align:right">
                         用户名:
                      </td>
                      <td>
                          <asp:TextBox ID="UserNameBox" runat="server"></asp:TextBox>

                      </td>
                  </tr>
                  <tr><td>&nbsp</td></tr>
                  <tr>
                      <td style="text-align:right">
                         密码:
                      </td>
                      <td>
                          <asp:TextBox ID="PasswordBox" runat="server" TextMode="Password"></asp:TextBox>

                      </td>
                 </tr>
                 <tr><td>&nbsp</td></tr>

                 <tr>
                      <td style="text-align:right">
                         确认密码:
                      </td>
                      <td>
                          <asp:TextBox ID="RePasswordBox" runat="server" TextMode="Password"></asp:TextBox>

                      </td>
                 </tr>
                 <tr><td>&nbsp</td></tr>

                 <tr>
                      <td style="text-align:right">
                         用户类型:
                      </td>
                      <td style="text-align:center">
                          <asp:RadioButtonList ID="RadioButtonList1" runat="server" 
                              RepeatDirection="Horizontal" Width="220px">
                              <asp:ListItem Value="0">管理员</asp:ListItem>
                              <asp:ListItem Value="1">一般用户</asp:ListItem>
                              
                          </asp:RadioButtonList>

                      </td>
                 </tr>
                 <tr><td>&nbsp</td></tr>

                 </table>
             </div>

            <br />
            <asp:UpdatePanel ID="UpdatePanel1" runat="server">
                <ContentTemplate>
                    <asp:Label ID="Label1" Visible="false" runat="server" ForeColor="Green"></asp:Label>
                </ContentTemplate>
                <Triggers>
                    <asp:AsyncPostBackTrigger ControlID="CreateUserButton" EventName="Click"/>
                </Triggers>
            </asp:UpdatePanel>
            <br />
            <br />
            <asp:Button ID="CreateUserButton" runat="server" Text="创建新用户" ForeColor="#776600"  OnClick="Create_User_Button_Click"/>
            <br /> 
          </td>
        </tr>
    </table>


</asp:Content>

