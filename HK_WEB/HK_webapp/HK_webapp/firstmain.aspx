<%@ Page Language="C#" MasterPageFile="~/NavMaster.master" AutoEventWireup="true" CodeBehind="firstmain.aspx.cs" Inherits="HK_webapp.firstmain" %>

<asp:Content ID="Content_mainfirst" ContentPlaceHolderID="RightContent" runat="Server">
    
    <asp:ScriptManager ID="ScriptManager1" runat="server"></asp:ScriptManager>
    <div id="top_band" style="background-color:bisque">
        <table>
            <tr>
                <td>&nbsp;&nbsp<asp:HyperLink ID="Vib_system" runat="server"  Font-Underline="True" ForeColor="blue" Text="振动系统" NavigateUrl="vibmain.aspx"></asp:HyperLink>&nbsp;&nbsp</td>        
                <td>| &nbsp;&nbsp<asp:HyperLink ID="DTS_system" runat="server"  Font-Underline="True" ForeColor="blue" Text="DTS测温系统" NavigateUrl="dtsmain.aspx"></asp:HyperLink>&nbsp;&nbsp</td>
                <td>| &nbsp;&nbsp<asp:HyperLink ID="Botda_system" runat="server"  Font-Underline="True" ForeColor="blue" Text="BOTDA应变测量系统" NavigateUrl="botdamain.aspx"></asp:HyperLink>&nbsp;&nbsp</td>    
            </tr>

        </table>
    </div>
    <h3>&nbsp;&nbsp;&nbsp<font color="blue">实时报警</font></h3>
    <asp:UpdatePanel ID="UpdatePanel1" runat="server">
        <ContentTemplate>
            <asp:Timer ID="Timer_main" runat="server" Interval="2000" OnTick="Timer_main_Tick"></asp:Timer>
            <table>
                <tr>
                <td>&nbsp;&nbsp </td>
                <td>                    
                     <div  id="vib_info" style="background-color:#DDDDDD;min-height:100%;width:550px;float:left;height:500px; border:1px solid red; padding:10px 10px;" align="left">
                          <img src="images\\icon_next.gif" /><b>振动报警:</b>
                          <br/>                                                                
                          &nbsp;&nbsp;&nbsp;当前共有未处理报警: <asp:Label ID="Label_vi_total" runat="server" ForeColor="red"></asp:Label>个
                          <br/>                           
                           <table align="center">
                                <tr align="center">
                                    <td>序号</td> <td align="center">报警时间</td> <td>通道号</td> <td>位置</td> <td>报警等级</td><td>&nbsp</td>
                                </tr>
                                <tr align="center">
                                    <td>
                                        <asp:Label ID="Label_vi_id1" runat="server" Text="" Visible="true"></asp:Label>
                                    </td> 
                                    <td width="190px"><asp:Label ID="Label_vi_time1" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_vi_ch1" runat="server" Text=""></asp:Label></td>
                                    <td width="100px"><asp:Label ID="Label_vi_pos1" runat="server" Text=""></asp:Label></td>
                                    <td width="70px"><asp:Label ID="Label_vi_level1" runat="server" Text=""></asp:Label></td>
                                    <td><asp:LinkButton ID="Button_vi1" AutoPostBack="True" runat="server" OnClick="Link_vi1_OnClick" Visible="false">详情</asp:LinkButton></td>
                                </tr>
                                <tr align="center">
                                    <td>
                                        <asp:Label ID="Label_vi_id2" runat="server" Text="" Visible="true"></asp:Label>
                                    </td> 
                                    <td><asp:Label ID="Label_vi_time2" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_vi_ch2" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_vi_pos2" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_vi_level2" runat="server" Text=""></asp:Label></td>
                                    <td><asp:LinkButton ID="Button_vi2" AutoPostBack="True" runat="server" OnClick="Link_vi2_OnClick" Visible="false">详情</asp:LinkButton></td>
                                </tr>
                                <tr align="center">
                                    <td>
                                        <asp:Label ID="Label_vi_id3" runat="server" Text="" Visible="true"></asp:Label>
                                    </td> 
                                    <td><asp:Label ID="Label_vi_time3" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_vi_ch3" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_vi_pos3" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_vi_level3" runat="server" Text=""></asp:Label></td>
                                    <td><asp:LinkButton ID="Button_vi3" AutoPostBack="True" runat="server" OnClick="Link_vi3_OnClick" Visible="false">详情</asp:LinkButton></td>
                                </tr>
                            </table>
                            <br/>
                            <img src="images\\icon_next.gif" /><b>振动光纤状态报警：</b>
                             <br/>
                            &nbsp;&nbsp;&nbsp;当前共有未处理光纤状态报警: <asp:Label ID="Label_fiber_alarm_num" runat="server" ForeColor="red"></asp:Label>个
                          <br/>
                          <table align="center">
                                <tr align="center">
                                    <td>序号</td> <td align="center">报警时间</td> <td>通道号</td> <td>位置</td> <td>光纤状态</td><td>&nbsp</td>
                                </tr>
                                <tr align="center">
                                    <td>
                                        <asp:Label ID="Label_fib_id1" runat="server" Text="" Visible="true"></asp:Label>
                                    </td> 
                                    <td width="180px"><asp:Label ID="Label_fib_time1" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_fib_ch1" runat="server" Text=""></asp:Label></td>
                                    <td width="90px"><asp:Label ID="Label_fib_pos1" runat="server" Text=""></asp:Label></td>
                                    <td width="100px"><asp:Label ID="Label_fib_status1" runat="server" Text=""></asp:Label></td>
                                    <td><asp:LinkButton ID="Button_fib1" AutoPostBack="True" runat="server" OnClick="Link_fib1_OnClick" Visible="false">详情</asp:LinkButton></td>
                                </tr>
                                <tr align="center">
                                    <td>
                                        <asp:Label ID="Label_fib_id2" runat="server" Text="" Visible="true"></asp:Label>
                                    </td> 
                                    <td><asp:Label ID="Label_fib_time2" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_fib_ch2" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_fib_pos2" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_fib_status2" runat="server" Text=""></asp:Label></td>
                                    <td><asp:LinkButton ID="Button_fib2" AutoPostBack="True" runat="server" OnClick="Link_fib2_OnClick" Visible="false">详情</asp:LinkButton></td>
                                </tr>
                                <tr align="center">
                                    <td>
                                        <asp:Label ID="Label_fib_id3" runat="server" Text="" Visible="true"></asp:Label>
                                    </td> 
                                    <td><asp:Label ID="Label_fib_time3" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_fib_ch3" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_fib_pos3" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_fib_status3" runat="server" Text=""></asp:Label></td>
                                    <td><asp:LinkButton ID="Button_fib3" AutoPostBack="True" runat="server" OnClick="Link_fib3_OnClick" Visible="false">详情</asp:LinkButton></td>
                                </tr>
                            </table>
                            <br/>
                            <img src="images\\icon_next.gif" /><b>BOTDA应变报警：</b>
                            <br/>
                            &nbsp;&nbsp;&nbsp; 当前共有未处理BOTDA应变报警: <asp:Label ID="Label_botda_alarm_num" runat="server" ForeColor="red"></asp:Label>个

                            <br/>
                            <table align="center">
                                <tr align="center">
                                    <td width="60px">序号</td> <td align="center">报警时间</td> <td>通道号</td> <td>位置</td> <td>应变最大值</td><td>&nbsp</td>
                                </tr>
                                <tr align="center">
                                    <td width="50">
                                        <asp:Label ID="Label_botda_id1" runat="server" Text="" Visible="true"></asp:Label>
                                    </td> 
                                    <td width="180px"><asp:Label ID="Label_botda_time1" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_botda_ch1" runat="server" Text=""></asp:Label></td>
                                    <td width="80px"><asp:Label ID="Label_botda_pos1" runat="server" Text=""></asp:Label></td>
                                    <td width="100px"><asp:Label ID="Label_botda_value1" runat="server" Text=""></asp:Label></td>
                                    <td><asp:LinkButton ID="Button_botda1" AutoPostBack="True" runat="server" OnClick="Link_bodta1_OnClick" Visible="false">详情</asp:LinkButton></td>
                                </tr>
                                <tr align="center">
                                    <td>
                                        <asp:Label ID="Label_botda_id2" runat="server" Text="" Visible="true"></asp:Label>
                                    </td> 
                                    <td><asp:Label ID="Label_botda_time2" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_botda_ch2" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_botda_pos2" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_botda_value2" runat="server" Text=""></asp:Label></td>
                                    <td><asp:LinkButton ID="Button_botda2" AutoPostBack="True" runat="server" OnClick="Link_bodta2_OnClick" Visible="false">详情</asp:LinkButton></td>
                                </tr>
                                <tr align="center">
                                    <td>
                                        <asp:Label ID="Label_botda_id3" runat="server" Text="" Visible="true"></asp:Label>
                                    </td> 
                                    <td><asp:Label ID="Label_botda_time3" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_botda_ch3" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_botda_pos3" runat="server" Text=""></asp:Label></td>
                                    <td><asp:Label ID="Label_botda_value3" runat="server" Text=""></asp:Label></td>
                                    <td><asp:LinkButton ID="Button_botda3" AutoPostBack="True" runat="server" OnClick="Link_botda3_OnClick" Visible="false">详情</asp:LinkButton></td>
                                </tr>
                            </table>
                            <br/>




                    </div>
                                   
                </td>
                <td>&nbsp;&nbsp;&nbsp;&nbsp</td> 
                <td>
                    <div  id="alarm_detail" style="background-color:#DDDDDD;min-height:100%;width:650px;float:left; height:500px;padding:10px 10px;"  align="left">

                         <asp:Panel ID="Panel_vib_detail" runat="server" > 
                           <table>
                            <tr>
                                <td>&nbsp;&nbsp;&nbsp;&nbsp</td>

                            <td>
                                <br/>
                             <b><asp:Label ID="label_vib_head" runat="server" ForeColor="blue" Text="Label"></asp:Label><asp:Label ID="label_vib_confirm" runat="server" Text=""></asp:Label></b>
                             <asp:Label ID="Label_vib_id_invisable" runat="server" Text="Label" Visible="false"></asp:Label>
                             <br/>
                             <br/>
                             
                             <font color="blue">报警详情：</font>
                             
                             <table>
                                 <tr>
                                     <td width="300px">通道号： 
                                         <asp:Label ID="Label_vi_de_chid" runat="server" Text=""></asp:Label>
                                     </td>
                                     <td width="350px">样本号： 
                                         <asp:Label ID="Label_vi_de_sampleid" runat="server" Text=""></asp:Label>
                                     </td>


                                 </tr>
                                 <tr><td></td></tr>
                                 <tr>
                                     <td width="300px">报警时间： 
                                         <asp:Label ID="Label_vi_de_time" runat="server" Text=""></asp:Label>
                                     </td>
                                     <td width="350px">
                                         报警等级： <asp:Label ID="Label_vi_de_level" runat="server" Text=""></asp:Label>
                                     </td>
                                  </tr>
                                  <tr><td></td></tr>
                                  <tr>
                                     <td width="200px">
                                         报警最大强度： <asp:Label ID="Label_vi_de_maxi" runat="server" Text=""></asp:Label> 
                                     </td>
                                     <td width="250px">
                                         报警位置： <asp:Label ID="Label_vi_de_pos" runat="server" Text=""></asp:Label> 
                                     </td>
                                 </tr>
                                 <tr>
                                     <td width="200px">
                                         报警宽度： <asp:Label ID="Label_vi_de_width" runat="server" Text=""></asp:Label>
                                     </td>
                                     <td width="200px">
                                         报警可信度： <asp:Label ID="Label_vi_de_possi" runat="server" Text=""></asp:Label>
                                     </td>

                                 </tr>
                                 <tr><td>&nbsp;</td></tr>
                                 
                             </table>

                             <br/>
                             <br/>
                             <table align="center">
                                 <tr align ="left">
                                     <td width ="100px">
                                         <asp:Button ID="Button_vib_confirm" runat="server" Text="确认" OnClick="Button_vib_confirm_Click" />

                                     </td>
                                     <td width ="100px">
                                         <asp:Button ID="Button_vib_misalarm" runat="server" Text="误报" OnClick="Button_vib_misalarm_Click"/>
                                     </td>

                                 </table>
                               
                         </td>
                         </tr>
                         </table>
                         </asp:Panel>



                         <asp:Panel ID="Panel_fiber_detail" runat="server" > 
                             <br />
                             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                             <b><asp:Label ID="label_fib_head" runat="server" ForeColor="blue" Text="Label"></asp:Label><asp:Label ID="label_fib_confirm" runat="server" Text=""></asp:Label></b>
                             <asp:Label ID="Label_fib_id_invisable" runat="server" Text="Label" Visible="false"></asp:Label>
                             <br/>
                             <br/>
                             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                             <font color="blue">报警详情：</font>
                             <table>
                                 <tr>
                                     <td> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <td>
                                     <td>
                                         <table>
                                             <tr>
                                                 <td width="300px">通道号： 
                                                     <asp:Label ID="Label_fib_de_chid" runat="server" Text=""></asp:Label>
                                                 </td>

                                                 <td width="350px">报警时间： 
                                                      <asp:Label ID="Label_fib_de_time" runat="server" Text=""></asp:Label>
                                                 </td>
                                             </tr>

                                             <tr> 
                                                 <td width="300px">
                                                     光纤状态： <asp:Label ID="Label_fib_de_sta" runat="server" Text=""></asp:Label> 
                                                 </td>
                                                 <td width="350px">
                                                     报警位置： <asp:Label ID="Label_fib_de_pos" runat="server" Text=""></asp:Label> 
                                                 </td>
                                             </tr>

                                             <tr><td>&nbsp;</td></tr>
                                             <tr>
                                                <td><font color="blue">该报警的光纤数据：</font></td>
                                             </tr>
                                        </table>
                                        <table>
                                            <tr>
                                                <td>
                                                    光纤生产厂商： <asp:Label ID="Label_fib_de_fproducer" runat="server" Text=""></asp:Label>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td>
                                                    光纤型号： <asp:Label ID="Label_fib_de_ftype" runat="server" Text=""></asp:Label>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td>
                                                    光纤长度： <asp:Label ID="Label_fib_de_flength" runat="server" Text=""></asp:Label>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td>
                                                    光纤生产日期： <asp:Label ID="Label_fib_de_fdate" runat="server" Text=""></asp:Label>
                                                </td>
                                            </tr>

                                       </table>
                                   </td>
                                 </tr>
                             </table>
                             <br/>
                             <br/>
                             <table align="center">
                                 <tr align ="center">
                                     <td width ="100px">
                                         <asp:Button ID="Button_fib_confirm" runat="server" Text="确认" OnClick="Button_fib_confirm_Click" />

                                     </td>
                                     <td width ="100px">
                                         <asp:Button ID="Button_fib_misalarm" runat="server" Text="误报" OnClick="Button_fib_misalarm_Click" />
                                     </td>

                                  </table>
                               

                         </asp:Panel>


                        
                         <asp:Panel ID="Panel_botda_detail" runat="server" > 
                             <br/>
                             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                             <b><asp:Label ID="label_botda_head" runat="server" ForeColor="blue" Text="Label"></asp:Label><asp:Label ID="label_botda_confirm" runat="server" Text=""></asp:Label></b>
                             <asp:Label ID="Label_botda_id_invisable" runat="server" Text="Label" Visible="false"></asp:Label>
                             <br/>
                             <br/>
                             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                             <font color="blue">报警详情：</font>
                             <table>
                                 <tr>
                                     <td> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<td>
                                     <td>
                                         <table>
                                             <tr>
                                                 <td width="300px">通道号： 
                                                     <asp:Label ID="Label_botda_de_chid" runat="server" Text=""></asp:Label>
                                                 </td>

                                                 <td width="350px">报警时间： 
                                                      <asp:Label ID="Label_botda_de_time" runat="server" Text=""></asp:Label>
                                                 </td>
                                             </tr>
                                             <tr><td>&nbsp;&nbsp;</td></tr>

                                             <tr> 
                                                 <td width="300px">
                                                     报警起始位置： <asp:Label ID="Label_botda_de_start_pos" runat="server" Text=""></asp:Label> 
                                                 </td>
                                                 <td width="450px">
                                                     报警结束位置： <asp:Label ID="Label_botda_de_end_pos" runat="server" Text=""></asp:Label> 
                                                 </td>
                                             </tr>
                                             <tr><td>&nbsp;&nbsp;</td></tr>
                                             <tr> 
                                                 <td width="300px">
                                                     报警中央位置： <asp:Label ID="Label_botda_de_cent_pos" runat="server" Text=""></asp:Label> 
                                                 </td>
                                                 <td width="450px">
                                                     报警类型： <asp:Label ID="Label_botda_de_alarm_type" runat="server" Text=""></asp:Label> 
                                                 </td>
                                             </tr>
                                             <tr><td>&nbsp;&nbsp;</td></tr>
                                             <tr> 
                                                 <td width="300px">
                                                     最大应变值： <asp:Label ID="Label_botda_max_value" runat="server" Text=""></asp:Label> 
                                                 </td>
                                                 <td width="450px">
                                                     报警阈值： <asp:Label ID="Label_botda_limit_value" runat="server" Text=""></asp:Label> 
                                                 </td>
                                             </tr>

                                             <tr><td>&nbsp;</td></tr>

                                        </table>

                                   </td>
                                 </tr>
                             </table>
                             <br/>
                             <br/>
                             <table align="center">
                                 <tr align ="center">
                                     <td width ="100px">
                                         <asp:Button ID="Button_botda_confirm" runat="server" Text="确认" OnClick="Button_botda_confirm_Click" />

                                     </td>
                                     <td width ="100px">
                                         <asp:Button ID="Button_botda_misalarm" runat="server" Text="误报" OnClick="Button_botda_misalarm_Click" />
                                     </td>

                                  </table>
                               
                        </asp:Panel>
                        <asp:Panel ID="Panel_main_img" runat="server" >
                            <asp:Image ID="Image1" ImageUrl="main1.png" Width="650px" Height="500px" runat="server" />
                        </asp:Panel>
                  
                    </div>
                </td>

             </tr>
         </table>

       </ContentTemplate>

    </asp:UpdatePanel>
    <asp:SqlDataSource ID="SqlDataSource_vib" runat="server"  ProviderName="System.Data.Odbc" EnableCaching="true"></asp:SqlDataSource>

</asp:Content>
