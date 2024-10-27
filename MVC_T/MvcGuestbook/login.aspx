<%@ Page Language="C#" MasterPageFile="~/MainMaster.master" AutoEventWireup="true" CodeBehind="login.aspx.cs" Inherits="MvcGuestbook.login" %>


<asp:Content ID="Content_login" ContentPlaceHolderID="MainContent" runat="Server">
    <script type="text/javascrpt" src="~/Scripts/vue.js"></script>
    <script type="text/javascrpt" src="~/Scripts/index.js"></script>
    <script type="text/javascrpt" src="~/Scripts/jquery-3.6.0.js"></script>
<div class="main_content" width="100%" height="100%">
    <br/><br />
    <br/><br />
    <br/><br />


    <table  border="0" align="center" cellpadding="0"cellspacing="0" id="Table1">
        <tr>
            <td> 
               <strong><font color="#3F4F70" size="5">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;用户登录</font></strong>
               <br/>
               <br/>
               <font color="#8800ff" size="2">如无账号，请与系统管理员联系！</font>
               <div id="login" align="center" style="background-color:#F2F2F2;width:300px;border-radius:5px;">
                  <table style="width:100%;text-align:center;" border="0">
                  <tr><td>&nbsp</td></tr>
                  <tr>
                      <td style="text-align:right">
                         用户名:
                      </td>
                      <td>
                          <asp:TextBox ID="UserNameBox" runat="server" class="inputboxlogin"></asp:TextBox>

                      </td>
                  </tr>
                  <tr><td>&nbsp</td></tr>
                  <tr>
                      <td style="text-align:right">
                         密码:
                      </td>
                      <td>
                          <asp:TextBox ID="PasswordBox" runat="server" TextMode="Password" class="inputboxlogin"></asp:TextBox>

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
            <asp:Button ID="Button1" runat="server" Text="登录" class="submit_button" OnClick="Button1_Click" Height="25px" Width="48px"/>
                <!--
            <div id="btn_area">
                <el-button type="primary" size="small" round>创建新用户</el-button>   <a href="~/Home/About"><el-button type="primary" size="small" round><div class="button" style="color:#FFFFFF;">登出</div></el-button></a>

            </div>
                -->

            <br /> 
          </td>
        </tr>
    </table>
    <br><br /><br />
    <br><br /><br />
    <br><br /><br />
    <br><br /><br />
</div>


</asp:Content>

