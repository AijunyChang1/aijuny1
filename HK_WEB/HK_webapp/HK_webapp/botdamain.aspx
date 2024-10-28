<%@ Page Language="C#" MasterPageFile="~/NavMaster.master" AutoEventWireup="true" CodeBehind="botdamain.aspx.cs" Inherits="HK_webapp.botdamain" %>

<%@ Register Assembly="System.Web.DataVisualization, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" Namespace="System.Web.UI.DataVisualization.Charting" TagPrefix="asp" %>
<asp:Content ID="Content_mainfirst" ContentPlaceHolderID="RightContent" runat="Server">

    <asp:ScriptManager ID="ScriptManager1" runat="server"></asp:ScriptManager>
    <div id="top_band" style="background-color:bisque">
        <table>
            <tr>
                <td>&nbsp;&nbsp<asp:HyperLink ID="botda_Detail" runat="server"  Font-Underline="True" ForeColor="blue" Text="Botda报警历史数据查询" NavigateUrl="botda_alarm_detail.aspx"></asp:HyperLink>&nbsp;&nbsp</td>        
                <td>| &nbsp;&nbsp<asp:HyperLink ID="botda_data_detail" runat="server"  Font-Underline="True" ForeColor="blue" Text="Botda应变历史数据查询" NavigateUrl="botda_data_detail.aspx"></asp:HyperLink>&nbsp;&nbsp</td>
                <td>| &nbsp;&nbsp<asp:HyperLink ID="HyperLink_Main" runat="server"  Font-Underline="True" ForeColor="blue" Text="返回首页" NavigateUrl="firstmain.aspx"></asp:HyperLink>&nbsp;&nbsp</td>    
            </tr>

        </table>
    </div>

    <br/>
    <div id="chart_div1" style="background-color:#DDDDDD;width:630px;float:left;height:560px; border:1px solid red; padding:10px 10px;" align="left">
    <h3>&nbsp;&nbsp;&nbsp<font color="blue">BOTDA 实时应变图</font></h3>

    <asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <asp:Timer ID="Timer_main" runat="server" Interval="20000" OnTick="Timer_main_Tick"></asp:Timer>

        <table>
        <tr>
             <td>&nbsp;</td>
             <td><font color="purple">数据采集时间:</font> <asp:Label ID="Label1" runat="server" Text="Label" ForeColor="ButtonShadow"></asp:Label></td> 
        </tr>
        <tr>
            <td>&nbsp;</td>
            <td>
            <asp:Chart ID="Chart1" runat="server" Height="400px" Width="600px" BackColor="Yellow" BackGradientStyle="TopBottom" BackSecondaryColor="Orange" BorderlineWidth="1" EnableTheming="False" BorderlineColor="Transparent" >
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
                    <asp:Title Name="Title1" Text="BOTDA实时应变图" Font="华文楷体, 16.2pt, style=Bold" ForeColor="#660033"></asp:Title>
                </Titles>
                
                <BorderSkin SkinStyle="FrameThin3" BackColor="DodgerBlue" BackImageTransparentColor="White" BackSecondaryColor="Transparent" />
                
            </asp:Chart>
            </td>
         </tr>
         <tr>
              <td>&nbsp;</td>
              <td><font color="purple">横轴: 距离起始点光纤长度（米）&nbsp;&nbsp;&nbsp;&nbsp;纵轴: 应变值</font>

         </tr>
         </table>

    </ContentTemplate>
    </asp:UpdatePanel>
    </div>

    <div id="chart_div2" style="background-color:#DDDDDD;width:620px;float:left;height:560px; border:1px solid red; padding:10px 10px;" align="left">
         <h3>&nbsp;&nbsp;&nbsp<font color="blue">BOTDA报警类型占比图</font></h3>
        <!--
        <asp:UpdatePanel ID="UpdatePanel2" runat="server">
            <ContentTemplate>
                -->
                <table>
                <tr>
                     <td>&nbsp;</td>
                     <td><font color="purple">数据最后更新时间:</font> <asp:Label ID="Label2" runat="server" Text="Label" ForeColor="ButtonShadow"></asp:Label></td> 
                </tr>
                <tr>
                    <td>&nbsp;</td>
                    <td>
                       <asp:Chart ID="Chart2" runat="server" Height="400px" Width="600px" BackColor="Yellow" BackGradientStyle="TopBottom" BackSecondaryColor="Orange" BorderlineWidth="1" EnableTheming="False" >
                           <Legends >
                               <asp:Legend DockedToChartArea="ChartArea1" Name="Legend1" BackColor="255, 255, 0"></asp:Legend>
                           </Legends>
                           <Series>
                              <asp:Series Name="Series1" YValuesPerPoint="4" ChartType="Pie" CustomProperties="DrawingStyle=Cylinder" Color="Red" >
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
                              <asp:Title Name="Title1" Text="BOTDA报警类型占比图" Font="华文楷体, 16.2pt, style=Bold" ForeColor="#660033"></asp:Title>
                           </Titles>
                
                          <BorderSkin SkinStyle="FrameThin3" BackColor="DodgerBlue" />               
                       </asp:Chart>

                    </td>
                </tr>
                </table>

<!--
            </ContentTemplate>

        </asp:UpdatePanel>
        -->


    </div>

    <!--

    <script type="text/javascript">

        alert("hello");

   </script>
    -->

                    <!--
                <Points>
                    <asp:DataPoint AxisLabel="火箭" YValues="17" />
                    <asp:DataPoint AxisLabel="湖人" YValues="16" />
                    <asp:DataPoint AxisLabel="公牛" YValues="6" />


                </Points>
                -->

<br/>
<br/>



</asp:Content>

