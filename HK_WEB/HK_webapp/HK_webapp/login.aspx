<%@ Page Language="C#" MasterPageFile="~/MainMaster.master" AutoEventWireup="true" CodeBehind="login.aspx.cs" Inherits="HK_webapp.login" %>


<asp:Content ID="Content_login" ContentPlaceHolderID="MainContent" runat="Server">
    <br/>
    <br/>
    <br/>

    <table  border="0" align="center" cellpadding="0"cellspacing="0" id="Table1">
        <tr>
            <td> 
               <strong><font color="blue" size="5">用户登录</font></strong>
               <br/>
               <br/>
               <font color="#8800ff" size="2">如无账号，请与系统管理员联系！</font>
               <div id="login" align="center" style="background-color:#DDDDDD;width:300px;">
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

                 </table>
             </div>


            <br />
            <asp:RequiredFieldValidator ID="RequiredFieldValidator1" runat="server" ControlToValidate="UserNameBox" Display="Dynamic"   ErrorMessage="用户名不能为空!" ForeColor="Red"></asp:RequiredFieldValidator>
            <asp:RequiredFieldValidator ID="RequiredFieldValidator2" runat="server" ControlToValidate="PasswordBox" Display="Dynamic"  ErrorMessage="密码不能为空！" ForeColor="Red"></asp:RequiredFieldValidator>
            <asp:Label ID="Label1" Visible="false" runat="server" ForeColor="Green"></asp:Label>
            <br />
            <br />
            <asp:Button ID="Button1" runat="server" Text="登录"  OnClick="Button1_Click"/>
            <br /> 
          </td>
        </tr>
    </table>


</asp:Content>

