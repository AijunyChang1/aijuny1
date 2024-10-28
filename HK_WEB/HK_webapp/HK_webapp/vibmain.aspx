<%@ Page Language="C#" MasterPageFile="~/NavMaster.master" AutoEventWireup="true" CodeBehind="vibmain.aspx.cs" Inherits="HK_webapp.vibmain" %>

<asp:Content ID="Content_mainfirst" ContentPlaceHolderID="RightContent" runat="Server">

    <asp:ScriptManager ID="ScriptManager1" runat="server"></asp:ScriptManager>
    <div id="top_band" style="background-color:bisque">
        <table>
            <tr>
                <td>&nbsp;&nbsp<asp:HyperLink ID="Vib_Detail" runat="server"  Font-Underline="True" ForeColor="blue" Text="振动报警历史数据查询" NavigateUrl="vib_detail.aspx"></asp:HyperLink>&nbsp;&nbsp</td>        
                <td>| &nbsp;&nbsp<asp:HyperLink ID="HyperLink_Fib_Sta" runat="server"  Font-Underline="True" ForeColor="blue" Text="光纤状态历史数据查询" NavigateUrl="vib_fiber_sta.aspx"></asp:HyperLink>&nbsp;&nbsp</td>
                <td>| &nbsp;&nbsp<asp:HyperLink ID="HyperLink_Main" runat="server"  Font-Underline="True" ForeColor="blue" Text="返回首页" NavigateUrl="firstmain.aspx"></asp:HyperLink>&nbsp;&nbsp</td>    
            </tr>

        </table>
    </div>

<br/>
<br/>

<!--
<script type="text/javascript">
    function refresh_content() {
        vib_content.window.location.reload();
        //alert("hello");
    }

</script>
-->

<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
       <asp:Timer ID="TimerVibWarn" runat="server" Interval="2000" OnTick="TimerVibWarn_Tick"></asp:Timer>
       <table>
          <tr>
              <td>&nbsp;&nbsp;</td>
              <td>
                   <font color="blue"><b>现有身份识别事件共: <asp:Label ID="Label_figure_no" runat="server" Text="" ForeColor="Green"></asp:Label>&nbsp;个</b></font>
                   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                  <asp:Button ID="Button_clear_figure_event" runat="server"   OnClick="Button_Clear_on_click" Text="清除身份识别消息" BackColor="Silver" Font-Underline="True" />
                  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
                   <asp:Button ID="Button_restore_figure_event" runat="server"   OnClick="Button_Restore_on_click" Text="恢复身份识别消息" BackColor="Silver" Font-Strikeout="False" Font-Underline="True" BorderStyle="NotSet" />
              </td>
         </tr>
           
         <tr>
              <td>
                &nbsp;&nbsp;
              </td>
              <td>   
                <!-- <iframe src="vib_content.aspx" runat="server" name="vib_content" scrolling="no" frameborder="0" width="1200" height="800">  </iframe> -->
                   
                   <asp:DataList ID="DataList1" runat="server" CellPadding="4" DataKeyField="ID" DataSourceID="SqlDataSource1" ForeColor="#333333" 
                      OnItemCommand="DataList1_ItemCommand" RepeatColumns="5" Width="1200px" BorderStyle="Solid" RepeatDirection="Horizontal">
                      <ItemTemplate> 
                          
                          接受时间:<asp:Label ID="TimeLabel" runat="server" Text='<% #Eval("push_time")%>'/><br/>
                          通道号:<asp:Label ID="ChannelLabel" runat="server" Text='<% #Eval("channel")%>'/><br/>
                          <asp:LinkButton ID="LinkButton1" runat="server" CommandName="Select" Text="查看"></asp:LinkButton>
                      </ItemTemplate>
                      <AlternatingItemStyle BackColor="White" ForeColor="#284775" />
                      <FooterStyle BackColor="#5D7B9D" Font-Bold="True" ForeColor="White" />
                      <HeaderStyle BackColor="#5D7B9D" Font-Bold="True" ForeColor="White" />
                      <ItemStyle BackColor="#F7F6F3" ForeColor="#333333" />
                      <SelectedItemStyle BackColor="Yellow" Font-Bold="True" ForeColor="#FF00FF" />
                      <SelectedItemTemplate>
                          事件时间: <asp:Label ID="TimeLabel" runat="server" Text='<% #Eval("push_time","{0}")%>'/><br/>
                          序号:<asp:Label ID="IDLable" runat="server" Text='<%#Eval("ID","{0}")%>' /><br />
                          生产厂家: <asp:Label ID="ProducerLabel" runat="server" Text='<% #Eval("cable_producer","{0}")%>'/><br/>
                          生产日期: <asp:Label ID="DataLabel" runat="server" Text='<% #Eval("cable_produce_date","{0}")%>'/><br/>
                          电缆型号: <asp:Label ID="Label1" runat="server" Text='<% #Eval("cable_type","{0}")%>'/><br/>
                          电缆截面: <asp:Label ID="Label_di" runat="server" Text='<% #Eval("cable_d","{0}")%>'/>mm<br/>
                          缆芯材质:  <asp:Label ID="Label_material" runat="server" Text='<% #Eval("cable_material","{0}")%>'/><br/>
                      </SelectedItemTemplate>
                   </asp:DataList>
                   
                   
              </td>
        </tr>
        <tr><td>&nbsp;&nbsp;</td></tr>
        <tr>
            <td>&nbsp;&nbsp;</td>
            <td><font color="blue"><b>现有未处理振动报警: <asp:Label ID="Label_vi_total" runat="server" ForeColor="red"></asp:Label>&nbsp;个</b></font></td>
        </tr>  
        <tr>
           <td>&nbsp;</td>
           <td>
                <style>
                   .table-c table{border-left:2px solid #999; border-top:2px solid #999;}
                   .table-c table td{border-right:2px solid #999; border-bottom:2px solid #999; height:25px}
                   .table-c table th{border-right:2px solid #999; border-bottom:2px solid #999;}
                </style>
                <div class="table-c">
                    <table>
                         <tr style="background-color:#777;" align="center">
                              <th style="color:white;"><b>编号</b></th>
                              <th style="color:white;"><b>报警时间</b></th>
                              <th style="color:white;"><b>通道号</b></th>
                              <th style="color:white;"><b>报警等级</b></th>
                              <th style="color:white;"><b>样本号</b></th>
                              <th style="color:white;"><b>报警位置(米)</b></th>
                              <th style="color:white;"><b>报警宽度</b></th>
                              <th style="color:white;"><b>最大强度</b></th>
                              <th style="color:white;"><b>可信度</b></th>
                              <th style="color:white;"><b>动作</b></th>
                         </tr>
                         <tr  align="center">
                             <td width="80px"><asp:Label ID="Label_vi_id1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="220px"><asp:Label ID="Label_vi_time1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="90px"><asp:Label ID="Label_vi_ch1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="90px"><asp:Label ID="Label_vi_level1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="90px"><asp:Label ID="Label_vi_sample_no1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="110px"><asp:Label ID="Label_vi_pos1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="90px"><asp:Label ID="Label_vi_width1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="100px"><asp:Label ID="Label_vi_max_int1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="90px"><asp:Label ID="Label_vi_possi1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="180px">
                                 <asp:Button ID="Button_confirm1" runat="server" Text="确认" OnClick="Button_Con1_on_click" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                                 <asp:Button ID="Button_miss1" runat="server" Text="误报" OnClick="Button_Mis1_on_click" />
                             </td>
                         </tr>
                         <tr style="background-color:lightyellow;" align="center">
                             <td><asp:Label ID="Label_vi_id2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_time2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_ch2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_level2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_sample_no2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_pos2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_width2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_max_int2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_possi2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td>
                                 <asp:Button ID="Button_confirm2" runat="server" Text="确认" OnClick="Button_Con2_on_click" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                                 <asp:Button ID="Button_miss2" runat="server" Text="误报" OnClick="Button_Mis2_on_click" />
                             </td>
                         </tr>

                         <tr align="center">
                             <td><asp:Label ID="Label_vi_id3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_time3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_ch3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_level3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_sample_no3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_pos3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_width3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_max_int3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_vi_possi3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td>
                                 <asp:Button ID="Button_confirm3" runat="server" Text="确认" OnClick="Button_Con3_on_click" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                                 <asp:Button ID="Button_miss3" runat="server" Text="误报" OnClick="Button_Mis3_on_click" />
                             </td>
                         </tr>                   
                    </table>
                </div>
           </td>
         </tr>
         <tr><td>&nbsp;&nbsp <td> </tr>
         <tr>
             <td>&nbsp;&nbsp</td> 
             <td> <font color="blue"><b>现有未处理光纤异常报警: <asp:Label ID="Label_fib_no" runat="server" ForeColor="red"></asp:Label>&nbsp;个</b></font></td>
         </tr>
         <tr>
             <td>&nbsp;&nbsp</td> 
             <td>
                <style>
                   .table-s table{border-left:2px solid #999; border-top:2px solid #999;}
                   .table-s table td{border-right:2px solid #999; border-bottom:2px solid #999; height:25px}
                   .table-s table th{border-right:2px solid #999; border-bottom:2px solid #999;}
                </style>
                <div class="table-s">
                    <asp:Panel ID="Panel_fiber" runat="server" Visible="false">
                     <table>
                         <tr style="background-color:#777;" align="center">
                              <th style="color:white;"><b>编号</b></th>
                              <th style="color:white;"><b>报警时间</b></th>
                              <th style="color:white;"><b>通道号</b></th>
                              <th style="color:white;"><b>报警位置(米)</b></th>
                              <th style="color:white;"><b>光纤状态</b></th>
                              <th style="color:white;"><b>动作</b></th>
                         </tr>

                         <tr  align="center">
                             <td width="80px"><asp:Label ID="Label_fib_id1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="220px"><asp:Label ID="Label_fib_time1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="90px"><asp:Label ID="Label_fib_ch1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="110px"><asp:Label ID="Label_fib_pos1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="100px"><asp:Label ID="Label_fib_sta1" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td width="180px">
                                 <asp:Button ID="Button_fib_con1" runat="server" Text="确认" OnClick="Button_fib_Con1_on_click" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                                 <asp:Button ID="Button_fib_mis1" runat="server" Text="误报" OnClick="Button_fib_Mis1_on_click" />
                             </td>
                         </tr>

                         <tr style="background-color:lightyellow;" align="center">
                             <td><asp:Label ID="Label_fib_id2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_fib_time2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_fib_ch2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_fib_pos2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_fib_sta2" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td>
                                 <asp:Button ID="Button_fib_con2" runat="server" Text="确认" OnClick="Button_fib_Con2_on_click" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                                 <asp:Button ID="Button_fib_mis2" runat="server" Text="误报" OnClick="Button_fib_Mis2_on_click" />
                             </td>
                         </tr>

                         <tr  align="center">
                             <td><asp:Label ID="Label_fib_id3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_fib_time3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_fib_ch3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_fib_pos3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td><asp:Label ID="Label_fib_sta3" runat="server" Text="" Visible="true"></asp:Label></td>
                             <td>
                                 <asp:Button ID="Button_fib_con3" runat="server" Text="确认" OnClick="Button_fib_Con3_on_click" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                                 <asp:Button ID="Button_fib_mis3" runat="server" Text="误报" OnClick="Button_fib_Mis3_on_click" />
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
         <asp:AsyncPostBackTrigger ControlID="TimerVibWarn" EventName="Tick"/>
    </Triggers>
</asp:UpdatePanel>
 <asp:SqlDataSource ID="SqlDataSource1" runat="server"   ProviderName="System.Data.Odbc"></asp:SqlDataSource>





</asp:Content>
