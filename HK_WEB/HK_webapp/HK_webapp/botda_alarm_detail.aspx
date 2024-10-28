<%@ Page Language="C#" MasterPageFile="~/NavMaster.master" AutoEventWireup="true" CodeBehind="botda_alarm_detail.aspx.cs" Inherits="HK_webapp.botda_alarm_detail" %>

<asp:Content ID="Content_mainfirst" ContentPlaceHolderID="RightContent" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server"></asp:ScriptManager>
    <div id="top_band" style="background-color:bisque">
        <table>
            <tr>
                <td>&nbsp;&nbsp <asp:HyperLink ID="HyperLink_Botda_Data" runat="server"  Font-Underline="True" ForeColor="blue" Text="Botda应变历史数据查询" NavigateUrl="botda_data_detail.aspx"></asp:HyperLink>&nbsp</td>
                <td>| <asp:HyperLink ID="HyperLink_BotdaMain" runat="server"  Font-Underline="True" ForeColor="blue" Text=" 返回BOTDA应变主页" NavigateUrl="botdamain.aspx"></asp:HyperLink>&nbsp</td> 
                <td>| <asp:HyperLink ID="HyperLink_Main" runat="server"  Font-Underline="True" ForeColor="blue" Text="返回首页" NavigateUrl="firstmain.aspx"></asp:HyperLink>&nbsp;&nbsp</td>                
            </tr>
        </table>
    </div>

    <h3>&nbsp;&nbsp;&nbsp<font color="blue">BOTDA应变报警历史数据查询</font></h3>
    <asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>

        <asp:Panel ID="Panel1" runat="server" >
           <table>
            <tr>
                <td>&nbsp; &nbsp;</td>
                <td>
                  <div id="Select"  style="height:140px;min-width:1220px;background-color:#DDDDDD;z-index:999;">
                  <table>                    
                     <tr>
                         <td> &nbsp; &nbsp </td>                        
                     </tr>
                     <tr>
                         <td> &nbsp; &nbsp </td>
                         <td  align="left" width="1100"><font color="blue">查 询 条 件：</font></td>
                     </tr>

                     <tr>
                         <td> &nbsp; &nbsp; &nbsp; &nbsp </td>            
                         <td> 
                             <table>
                             <tr style="width:1100px">
                                 <td valign="top">
                                     起始日期:  
                                     <asp:TextBox ID="TextBox1" runat="server" AutoPostBack="True" ToolTip="点击右边向下箭头选择日期"></asp:TextBox> 
                                     <asp:ImageButton ID="ImageButton1" runat="server" ImageUrl="images/on_1.png" OnClick="ImageButton1_click"/>
                                     <asp:Calendar ID="Calendar1" runat="server" Visible="False" BackColor="White"  OnSelectionChanged="Calendar1_SelectionChanged" BorderColor="#999999" CellPadding="4" DayNameFormat="Shortest" Font-Names="Verdana" Font-Size="8pt" ForeColor="Black" Height="180px" Width="200px" >
                                         <DayHeaderStyle BackColor="#CCCCCC" Font-Bold="True" Font-Size="7pt" />
                                         <NextPrevStyle VerticalAlign="Bottom" />
                                         <OtherMonthDayStyle ForeColor="#808080" />
                                         <SelectedDayStyle BackColor="#666666" Font-Bold="True" ForeColor="White" />
                                         <SelectorStyle BackColor="#CCCCCC" />
                                         <TitleStyle BackColor="#999999" BorderColor="Black" Font-Bold="True" />
                                         <TodayDayStyle BackColor="#CCCCCC" ForeColor="Black" />
                                         <WeekendDayStyle BackColor="#FFFFCC" />
                                     </asp:Calendar> 
                                 </td>        
                                 <td>&nbsp; &nbsp; &nbsp</td>
                                 <td valign="top">
                                     结束日期:  
                                     <asp:TextBox ID="TextBox2" runat="server" AutoPostBack="True" ToolTip="点击右边向下箭头选择日期"></asp:TextBox> 
                                     <asp:ImageButton ID="ImageButton2" runat="server" ImageUrl="images/on_1.png" OnClick="ImageButton2_click"/>                
                                     <asp:Calendar ID="Calendar2" runat="server" Visible="False" OnSelectionChanged="Calendar2_SelectionChanged" BackColor="White" BorderColor="#999999" CellPadding="4" DayNameFormat="Shortest" Font-Names="Verdana" Font-Size="8pt" ForeColor="Black" Height="180px" Width="200px">
                                         <DayHeaderStyle BackColor="#CCCCCC" Font-Bold="True" Font-Size="7pt" />
                                         <NextPrevStyle VerticalAlign="Bottom" />
                                         <OtherMonthDayStyle ForeColor="#808080" />
                                         <SelectedDayStyle BackColor="#666666" Font-Bold="True" ForeColor="White" />
                                         <SelectorStyle BackColor="#CCCCCC" />
                                         <TitleStyle BackColor="#999999" BorderColor="Black" Font-Bold="True" />
                                         <TodayDayStyle BackColor="#CCCCCC" ForeColor="Black" />
                                         <WeekendDayStyle BackColor="#FFFFCC" />
                                     </asp:Calendar> 
                                 </td>
                                 <td>&nbsp; &nbsp; &nbsp</td>
                                 <td valign="top">
                                     <asp:Panel ID="Panel_channel" runat="server">
                                     通道号: 
                                     <asp:DropDownList ID="DropDownList1" runat="server" Width="50">
                                         <asp:ListItem Value="0" Selected="True">所有</asp:ListItem>
                                         <asp:ListItem Value="1">1</asp:ListItem>
                                         <asp:ListItem Value="2">2</asp:ListItem>
                                         <asp:ListItem Value="3">3</asp:ListItem>
                                         <asp:ListItem Value="4">4</asp:ListItem>
                                     </asp:DropDownList>
                                     </asp:Panel>
                                 </td>   
                                 <td>&nbsp; &nbsp; &nbsp</td>
                                 <td valign="top">
                                     <asp:Panel ID="Panel_level" runat="server">
                                     报警类型: 
                                     <asp:DropDownList ID="DropDownList2" runat="server" Width="50" >
                                         <asp:ListItem Value="0">所有</asp:ListItem>
                                         <asp:ListItem Value="1">定值报警</asp:ListItem>
                                         <asp:ListItem Value="2">区域值差</asp:ListItem>
                                         <asp:ListItem Value="3">差值报警</asp:ListItem>
                                         <asp:ListItem Value="4">故障</asp:ListItem> 
                                         <asp:ListItem Value="4">故障恢复</asp:ListItem>  
                                     </asp:DropDownList>

                                    </asp:Panel>
                                </td> 
                                 <td>&nbsp; &nbsp; &nbsp</td>
                                 <td valign="top">
                                     <asp:Panel ID="Panel_confirm" runat="server">
                                     是否已确认: 
                                     <asp:DropDownList ID="DropDownConfirm" runat="server" Width="70" >
                                         <asp:ListItem Value="0">所有</asp:ListItem>
                                         <asp:ListItem Value="1">已确认</asp:ListItem>
                                         <asp:ListItem Value="2">未确认</asp:ListItem> 
                                         <asp:ListItem Value="3">误报</asp:ListItem> 
                                         
                                     </asp:DropDownList>

                                    </asp:Panel>
                                </td> 
                            </tr>
                           <tr><td>&nbsp; &nbsp;</td></tr>

                           <tr>
                               <td> &nbsp; &nbsp; &nbsp; &nbsp </td> 
                               <td> &nbsp; &nbsp; &nbsp; &nbsp </td> 
                               <td> &nbsp; &nbsp; &nbsp; &nbsp </td> 
                               <td> &nbsp; &nbsp; &nbsp; &nbsp </td> 
                               <td> &nbsp; &nbsp; &nbsp; &nbsp </td> 
                               <td> &nbsp; &nbsp; &nbsp; &nbsp </td> 
                               <td> &nbsp; &nbsp; &nbsp; &nbsp </td> 
                               <td> &nbsp; &nbsp; &nbsp; &nbsp </td> 
                               <td align="right">
                                   <asp:Button ID="Button1" runat="server" Text="查 询" OnClick="Button1_Click" />
                               </td>
                               
                           </tr>

                            </table>
                        </td> 
                     </tr>


                  </table>
                  </div>
                </td>
            </tr>
        </table>
      </asp:Panel>
        
      <br/>

      <table>
      <tr>
        <td> &nbsp; &nbsp;</td>
        <td>

  
        <asp:GridView ID="GridView1" runat="server" CellPadding="4" DataKeyNames="id"
            DataSourceID="SqlDataSource1" ForeColor="Black" GridLines="Vertical" 
            AutoGenerateColumns="False" 
            AllowPaging="True" AllowSorting="True" BackColor="White" 
            BorderColor="#DEDFDE" BorderStyle="None" BorderWidth="1px">
            <AlternatingRowStyle BackColor="White" />
            <Columns>
                <asp:BoundField DataField="id" HeaderText="编号" SortExpression="id" ItemStyle-Width="70" >
                    <ItemStyle HorizontalAlign="Center" Width="70px" />
                </asp:BoundField>
                <asp:BoundField DataField="alarm_time" HeaderText="报警时间" 
                    SortExpression="alarm_time" ItemStyle-Width="220" 
                    ItemStyle-HorizontalAlign="Center">
                <ItemStyle HorizontalAlign="Center" Width="220px" />
                </asp:BoundField>
                <asp:BoundField DataField="channel_id" HeaderText="通道号" 
                    SortExpression="channel_id" ItemStyle-Width="90" 
                    ItemStyle-HorizontalAlign="Center" >
                <ItemStyle HorizontalAlign="Center" Width="90px" />
                </asp:BoundField>
                <asp:BoundField DataField="alarm_type" HeaderText="报警类型" SortExpression="alarm_type"  ItemStyle-Width="90"
                    ItemStyle-HorizontalAlign="Center"  >
                <ItemStyle HorizontalAlign="Center" Width="90px"  />
                </asp:BoundField>
                <asp:BoundField DataField="begin_pos" HeaderText="开始位置" 
                    SortExpression="begin_pos" ItemStyle-Width="90" 
                    ItemStyle-HorizontalAlign="Center" >
                <ItemStyle HorizontalAlign="Center" Width="90px" />
                </asp:BoundField>
                <asp:BoundField DataField="end_pos" HeaderText="结束位置" 
                    SortExpression="end_pos" ItemStyle-Width="90" 
                    ItemStyle-HorizontalAlign="Center" >
                <ItemStyle HorizontalAlign="Center" Width="90px" />
                </asp:BoundField>
                <asp:BoundField DataField="cent_pos" HeaderText="中间位置" 
                    SortExpression="cent_pos" ItemStyle-Width="120" >
                <ItemStyle HorizontalAlign="Center" Width="120px" />
                </asp:BoundField>
                <asp:BoundField DataField="max_value" HeaderText="最大值" 
                    SortExpression="max_value" ItemStyle-Width="120" 
                    ItemStyle-HorizontalAlign="Center">
                <ItemStyle HorizontalAlign="Center" Width="120px" />
                </asp:BoundField>
                <asp:BoundField DataField="limen_value" HeaderText="阈值" 
                    SortExpression="limen_value" ItemStyle-Width="95" 
                    ItemStyle-HorizontalAlign="Center">
                <ItemStyle HorizontalAlign="Center" Width="95px" />
                </asp:BoundField>
                
                <asp:BoundField DataField="show_check" HeaderText="是否已确认" 
                    SortExpression="show_check" ItemStyle-Width="100" 
                    ItemStyle-HorizontalAlign="Center">
                <ItemStyle HorizontalAlign="Center" Width="100px" />
                </asp:BoundField>
            </Columns>
            <FooterStyle BackColor="#CCCC99" />
            <HeaderStyle BackColor="#6B696B" Font-Bold="True" ForeColor="White" />
            <PagerStyle BackColor="#F7F7DE" ForeColor="Black" HorizontalAlign="Right" />
            <RowStyle BackColor="#F7F7DE" />
            <SelectedRowStyle BackColor="#CE5D5A" Font-Bold="True" ForeColor="White" />
            <SortedAscendingCellStyle BackColor="#FBFBF2" />
            <SortedAscendingHeaderStyle BackColor="#848384" />
            <SortedDescendingCellStyle BackColor="#EAEAD3" />
            <SortedDescendingHeaderStyle BackColor="#575357" />
        </asp:GridView>

        <asp:Panel ID="Panel2" runat="server" Visible = "false">            
             <asp:Label ID="Label1" runat="server" ForeColor="red" Text="没有符合查询条件的记录"></asp:Label>
        </asp:Panel>

        <asp:Panel ID="Panel3" runat="server" Visible = "false">
             <asp:Label ID="Label2" runat="server"></asp:Label>
        </asp:Panel>

    </td>
    </tr>
  </table>



    </ContentTemplate>
    <Triggers>
   
    </Triggers>
    </asp:UpdatePanel>

    <asp:SqlDataSource ID="SqlDataSource1" runat="server" ProviderName="System.Data.Odbc"  EnableCaching="true">

    </asp:SqlDataSource>


</asp:Content>
