<%@ Page Language="C#" MasterPageFile="~/NavMaster.master" AutoEventWireup="true" CodeBehind="botda_data_detail.aspx.cs" Inherits="HK_webapp.botda_data_detail" %>

<asp:Content ID="Content_mainfirst" ContentPlaceHolderID="RightContent" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server"></asp:ScriptManager>
        <div id="top_band" style="background-color:bisque">
        <table>
            <tr>
                <td>&nbsp;&nbsp <asp:HyperLink ID="HyperLink_Botda_Alarm" runat="server"  Font-Underline="True" ForeColor="blue" Text="Botda报警历史数据查询" NavigateUrl="botda_alarm_detail.aspx"></asp:HyperLink>&nbsp</td>
                <td>| <asp:HyperLink ID="HyperLink_BotdaMain" runat="server"  Font-Underline="True" ForeColor="blue" Text=" 返回BOTDA应变主页" NavigateUrl="botdamain.aspx"></asp:HyperLink>&nbsp</td> 
                <td>| <asp:HyperLink ID="HyperLink_Main" runat="server"  Font-Underline="True" ForeColor="blue" Text="返回首页" NavigateUrl="firstmain.aspx"></asp:HyperLink>&nbsp;&nbsp</td>                
            </tr>
        </table>
    </div>
    <h3>&nbsp;&nbsp;&nbsp<font color="blue">BOTDA应变历史数据查询</font></h3>
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
                                     序号: 
                                         <asp:TextBox ID="TextBox_no" runat="server" Text=""></asp:TextBox>
                                         <asp:Label ID="Label_hide_select_str" runat="server" Text="Label" Visible="false"></asp:Label>
                                    </asp:Panel>

                                </td> 
                                 <td>&nbsp; &nbsp; &nbsp</td>

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
     </ContentTemplate>

     </asp:UpdatePanel>
     <br/>       
     <asp:UpdatePanel ID="UpdatePanel2" runat="server">
     <ContentTemplate> 
     <table>
         <tr>
             <td>
     <div id="show_table" width="700" float="left" align="left">
     <asp:Panel ID="Panel_show_table" runat="server">
        <table>
            <tr>
                <td> &nbsp; &nbsp;</td>
                <td>
                      <style>
                       .table-c table{border-left:2px solid #999; border-top:2px solid #999;}
                       .table-c table td{border-right:2px solid #999; border-bottom:2px solid #999; height:25px}
                       .table-c table th{border-right:2px solid #999; border-bottom:2px solid #999;}
                      </style>
                    <asp:Repeater ID="Repeater1" runat="server">
                        <HeaderTemplate>
                            <div class="table-c">
                            <table  >
                                <tr style="background-color:#777;" align="center">
                                    <th style="color:white;"><b>编号</b></th>
                                    <th style="color:white;"><b>时间</b></th>
                                    <th style="color:white;"><b>通道号</b></th>
                                    <th style="color:white;"><b>点距(米)</b></th>
                                    <th style="color:white;"><b>详细</b></th>

                                </tr>

                        </HeaderTemplate>
                        <ItemTemplate>
                            <tr align="center">
                                 <td width="50px"> <%# DataBinder.Eval(Container.DataItem,"id") %> </td>
                                 <td width ="210px"><%# DataBinder.Eval(Container.DataItem,"rece_time") %> </td>
                                 <td width="50px"><%# DataBinder.Eval(Container.DataItem,"channel_id") %> </td>
                                 <td width="70px"><%# DataBinder.Eval(Container.DataItem,"dot_len") %> </td>
                                 <td>
                                     
                                     <a href='botda_data_detail.aspx?no=<%# DataBinder.Eval(Container.DataItem,"id") %>'>瞬时应变图</a> </td>
                                 </td>
                            </tr>
                                                                                 

                        </ItemTemplate>


                        <AlternatingItemTemplate>
                            <tr style="background-color:lightyellow;" align="center">
                                 <td width="50px"> <%# DataBinder.Eval(Container.DataItem,"id") %> </td>
                                 <td><%# DataBinder.Eval(Container.DataItem,"rece_time") %> </td>
                                 <td><%# DataBinder.Eval(Container.DataItem,"channel_id") %> </td>
                                <td><%# DataBinder.Eval(Container.DataItem,"dot_len") %> </td>
                                 <td><a href='botda_data_detail.aspx?no=<%# DataBinder.Eval(Container.DataItem,"id") %>&page=<%=Lable_page.Text%>'>瞬时应变图</a> </td>
                            </tr>
                                                                                 

                        </AlternatingItemTemplate>

                        <FooterTemplate>
                            </table>
                            </div>
                        </FooterTemplate>
                    </asp:Repeater>

                    
                </td>
            </tr>
            <tr>
                <td>&nbsp;</td>

                <td >
                    <asp:Label ID="Lable1" runat="server" Text="当前页码为: "></asp:Label>
                    <asp:Label ID="Lable_page" runat="server" Text="1"></asp:Label>&nbsp;&nbsp;
                    <asp:Label ID="Lable2" runat="server" Text="总页码为: "></asp:Label>
                    <asp:Label ID="Lable_total_page" runat="server" Text="1"></asp:Label>&nbsp;&nbsp;
                    <asp:LinkButton ID="lnkbtnOne" runat="server"  OnClick="lnkbtnOne_Click">第一页</asp:LinkButton>&nbsp;&nbsp;
                    <asp:LinkButton ID="lnkbtnPrev" runat="server"   OnClick="lnkbtnPrev_Click">上一页</asp:LinkButton>&nbsp;&nbsp;
                    <asp:LinkButton ID="lnkbtnNext" runat="server"  OnClick="lnkbtnNext_Click">下一页</asp:LinkButton>&nbsp;&nbsp;
                    <asp:LinkButton ID="lnkbtnLast" runat="server"  OnClick="lnkbtnLast_Click">最后一页</asp:LinkButton>

                </td>
            </tr>
       </table>

       </asp:Panel>
       <asp:Panel ID="Panel_no_record" runat="server" Visible = "false">            
            &nbsp;&nbsp;&nbsp;&nbsp; <asp:Label ID="Label1" runat="server" ForeColor="red" Text="没有符合查询条件的记录"></asp:Label>
       </asp:Panel>

       </div>
                 
             </td>
             <td>

             <td>&nbsp;&nbsp;&nbsp;&nbsp;  </td>
            
             <td>

       <div id="show_chart" float="left" align="left">
           <asp:Panel ID="Panel_chart" runat="server" Visible="false">
           <table>
           <tr>
               <td>
                   <font color="purple">序号:</font><asp:Label ID="Label_chart_id" runat="server" Text="" ForeColor="ButtonShadow"></asp:Label> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                   <font color="purple">数据采集时间:</font> <asp:Label ID="Label_chart_time" runat="server" Text="Label" ForeColor="ButtonShadow"></asp:Label>
                   
               </td>
           </tr>
           <tr>
               <td>
            <asp:Chart ID="Chart1" runat="server" Height="300px" Width="600px" BackColor="Yellow" BackGradientStyle="TopBottom" BackSecondaryColor="Orange" BorderlineWidth="1" EnableTheming="False" BorderlineColor="Transparent" >
                <Legends >
                    <asp:Legend DockedToChartArea="ChartArea1" Name="Legend1" BackColor="255, 255, 0"></asp:Legend>
                </Legends>
                <Series>
                    <asp:Series Name="Series1" YValuesPerPoint="4" ChartType="Area" CustomProperties="DrawingStyle=Cylinder" Color="Red" >
                    </asp:Series>
                </Series>
                <ChartAreas>
                    <asp:ChartArea Name="ChartArea1" BackColor="White" ShadowColor="Transparent" Area3DStyle-Enable3D="false">
                        <AxisY LineColor="64,64,64,64" IsLabelAutoFit="false">
                            <LabelStyle Font="Trebuchet MS, 8.25pt, style=Bold"  />
                            <MajorGrid LineColor="64,64,64,64" />
                        </AxisY>
                    </asp:ChartArea>
                </ChartAreas>
                <Titles>
                    <asp:Title Name="Title1" Text="BOTDA瞬时应变图" Font="华文楷体, 16.2pt, style=Bold" ForeColor="#660033"></asp:Title>
                </Titles>
                
                <BorderSkin SkinStyle="FrameThin3" BackColor="DodgerBlue" BackImageTransparentColor="White" BackSecondaryColor="Transparent" />
                
             </asp:Chart>
             <td>
           </tr>
               <tr> 
                <td>
                    <font color="purple">横轴: 距离起始点光纤长度（米）&nbsp;&nbsp;&nbsp;&nbsp;纵轴: 应变值</font>

                </td>
               </tr>
               </table>

           </asp:Panel>


       </div>
                 </td>
             </tr>
         </table>

        </ContentTemplate>
        <Triggers>
   
        </Triggers>
    </asp:UpdatePanel>


    
       


</asp:Content>

