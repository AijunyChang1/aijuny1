using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data.Odbc;
using System.Data;


namespace HK_webapp
{
    public partial class vibmain : System.Web.UI.Page
    {
        static public string constr;
        static public string select_str;
        protected void Page_Load(object sender, EventArgs e)
        {
            string db_ip = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_IP"];
            string db_dsn = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_VIB_DSN"];
            string db_user = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_USER"];
            string db_password = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_PW"];
            string db_name = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_VIB_NAME"];

            constr = "dsn=" + db_dsn + ";server=" + db_ip + ";uid=" + db_user + ";database=" + db_name + ";port=3306;pwd=" + db_password;
            SqlDataSource1.ConnectionString = constr;
            if (!IsPostBack)
            {
                select_str = "SELECT hk_show_figure_event.id,hk_show_figure_event.channel, hk_show_figure_event.push_time, hk_cable_figure_id.cable_type,"+
                 "hk_cable_figure_id.cable_producer,hk_cable_figure_id.cable_produce_date, hk_cable_figure_id.cable_len, hk_cable_figure_id.cable_d,case hk_cable_figure_id.cable_material when 1 then '铜芯'"+
                 "when 2 then '铝芯' when 3 then '铜铝芯' end cable_material, hk_cable_figure_id.cable_annotation FROM hk_show_figure_event, hk_cable_figure_id where hk_show_figure_event.channel = hk_cable_figure_id.channel and hk_show_figure_event.is_show = 0 order by id desc limit 5;";
            }
            SqlDataSource1.SelectCommand = select_str;
            // Panel_fiber.Visible = false;
        }
        protected void TimerVibWarn_Tick(object sender, EventArgs e)
        {
            // DataList1.DataSource = SqlDataSource1;
            Label_fib_id1.Text = "";
            Label_fib_id2.Text = "";
            Label_fib_id3.Text = "";
            Label_fib_time1.Text = "";
            Label_fib_time2.Text = "";
            Label_fib_time3.Text = "";
            Label_fib_ch1.Text = "";
            Label_fib_ch2.Text = "";
            Label_fib_ch3.Text = "";
            Label_fib_pos1.Text = "";
            Label_fib_pos2.Text = "";
            Label_fib_pos3.Text = "";
            Label_fib_sta1.Text = "";
            Label_fib_sta2.Text = "";
            Label_fib_sta3.Text = "";

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            OdbcDataReader rd = db_vib.ExecQuerySql("select count(*) c from (select id from hk_show_figure_event where is_show=0) T;");
            if (rd.Read())
            {
                Label_figure_no.Text = rd["c"].ToString();
            }

            rd.Close();



            // OdbcDataReader rd = db_vib.ExecQuerySql("select count(*) c from (select id from hk_vib_event_detail where is_show=0 union select id from  hk_fiber_event_detail where is_show=0) T;");
            rd = db_vib.ExecQuerySql("select count(*) c from (select id from hk_vib_event_detail where is_show=0) T;");
            if (rd.Read())
            {
                Label_vi_total.Text = rd["c"].ToString();
            }

            rd.Close();
            rd = db_vib.ExecQuerySql("select id, push_time, channel_id, center_pos, level, sample_id, possibility, event_width, max_intensity from hk_vib_event_detail where is_show=0 order by id desc limit 3;");
            int i = 1;

            while (rd.Read())
            {
                if (i == 1)
                {

                    Label_vi_id1.Text = rd["id"].ToString();
                    Label_vi_time1.Text = rd["push_time"].ToString();
                    Label_vi_ch1.Text = rd["channel_id"].ToString();
                    Label_vi_pos1.Text = rd["center_pos"].ToString();
                    Label_vi_level1.Text = rd["level"].ToString();
                    Label_vi_sample_no1.Text = rd["sample_id"].ToString();
                    Label_vi_width1.Text = rd["event_width"].ToString();
                    Label_vi_max_int1.Text = rd["max_intensity"].ToString();
                    Label_vi_possi1.Text = rd["possibility"].ToString();
                }
                if (i == 2)
                {
                    Label_vi_id2.Text = rd["id"].ToString();
                    Label_vi_time2.Text = rd["push_time"].ToString();
                    Label_vi_ch2.Text = rd["channel_id"].ToString();
                    Label_vi_pos2.Text = rd["center_pos"].ToString();
                    Label_vi_level2.Text = rd["level"].ToString();
                    Label_vi_sample_no2.Text = rd["sample_id"].ToString();
                    Label_vi_width2.Text = rd["event_width"].ToString();
                    Label_vi_max_int2.Text = rd["max_intensity"].ToString();
                    Label_vi_possi2.Text = rd["possibility"].ToString();
                }
                if (i == 3)
                {
                    Label_vi_id3.Text = rd["id"].ToString();
                    Label_vi_time3.Text = rd["push_time"].ToString();
                    Label_vi_ch3.Text = rd["channel_id"].ToString();
                    Label_vi_pos3.Text = rd["center_pos"].ToString();
                    Label_vi_level3.Text = rd["level"].ToString();
                    Label_vi_sample_no3.Text = rd["sample_id"].ToString();
                    Label_vi_width3.Text = rd["event_width"].ToString();
                    Label_vi_max_int3.Text = rd["max_intensity"].ToString();
                    Label_vi_possi3.Text = rd["possibility"].ToString();
                }

                i = i + 1;

            }

            ////////////////////////////////////////////////////////////////////////////
            rd.Close();
            rd = db_vib.ExecQuerySql("select count(*) c from (select id from hk_fiber_event_detail where is_show=0 and fiber_stat<>'None') T;");
            if (rd.Read())
            {
                Label_fib_no.Text = rd["c"].ToString();
            }

            rd.Close();
            if (Label_fib_no.Text == "0")
            {
                Panel_fiber.Visible = false;
            }
            else
            {
                Panel_fiber.Visible = true;
                ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                rd = db_vib.ExecQuerySql("select id, push_time, channel_id, fiber_bk_len, case fiber_stat when 'Break' then '断纤' when 'NoFiber' " +
                    "then '光纤拔出' when 'None' then '光纤正常' when 'TooLong' then '光纤过长' end fiber_stat from hk_fiber_event_detail where is_show=0 and fiber_stat<>'None' order by id desc limit 3;");
                i = 1;

                while (rd.Read())
                {
                    if (i == 1)
                    {

                        Label_fib_id1.Text = rd["id"].ToString();
                        Label_fib_time1.Text = rd["push_time"].ToString();
                        Label_fib_ch1.Text = rd["channel_id"].ToString();
                        Label_fib_pos1.Text = rd["fiber_bk_len"].ToString();
                        Label_fib_sta1.Text = rd["fiber_stat"].ToString();
                    }
                    if (i == 2)
                    {
                        Label_fib_id2.Text = rd["id"].ToString();
                        Label_fib_time2.Text = rd["push_time"].ToString();
                        Label_fib_ch2.Text = rd["channel_id"].ToString();
                        Label_fib_pos2.Text = rd["fiber_bk_len"].ToString();
                        Label_fib_sta2.Text = rd["fiber_stat"].ToString();
                    }
                    if (i == 3)
                    {
                        Label_fib_id3.Text = rd["id"].ToString();
                        Label_fib_time3.Text = rd["push_time"].ToString();
                        Label_fib_ch3.Text = rd["channel_id"].ToString();
                        Label_fib_pos3.Text = rd["fiber_bk_len"].ToString();
                        Label_fib_sta3.Text = rd["fiber_stat"].ToString();
                    }

                    i = i + 1;

                }
                rd.Close();

            }

            db_vib.Close();
            db_vib.Dispose();

            DataList1.DataBind();
            DataList1.Visible = false;
            DataList1.Visible = true;

            //  UpdatePanel1.Update();
            ////////////////////////////////////////////
            // string parentJS = @"<script>parent.refresh_content();</script>";
            // ClientScript.RegisterStartupScript(this.GetType(), "clientscript", parentJS);


        }
        protected void DataList1_ItemCommand(object source, DataListCommandEventArgs e)
        {
            DataList1.SelectedIndex = e.Item.ItemIndex;
            DataList1.DataBind();

        }
        protected void Button_Con1_on_click(object sender, EventArgs e)
        {
            string vib_no = Label_vi_id1.Text;
            vib_no = vib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_vib_event_detail set is_show=1 where id=" + vib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();

        }
        protected void Button_Con2_on_click(object sender, EventArgs e)
        {
            string vib_no = Label_vi_id2.Text;
            vib_no = vib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_vib_event_detail set is_show=1 where id=" + vib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();

        }
        protected void Button_Con3_on_click(object sender, EventArgs e)
        {
            string vib_no = Label_vi_id3.Text;
            vib_no = vib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_vib_event_detail set is_show=1 where id=" + vib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();

        }

        protected void Button_Mis1_on_click(object sender, EventArgs e)
        {
            string vib_no = Label_vi_id1.Text;
            vib_no = vib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_vib_event_detail set is_show=2 where id=" + vib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();

        }
        protected void Button_Mis2_on_click(object sender, EventArgs e)
        {
            string vib_no = Label_vi_id2.Text;
            vib_no = vib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_vib_event_detail set is_show=2 where id=" + vib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();
        }
        protected void Button_Mis3_on_click(object sender, EventArgs e)
        {
            string vib_no = Label_vi_id3.Text;
            vib_no = vib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_vib_event_detail set is_show=2 where id=" + vib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();
        }

        protected void Button_fib_Con1_on_click(object sender, EventArgs e)
        {
            string fib_no = Label_fib_id1.Text;
            fib_no = fib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_fiber_event_detail set is_show=1 where id=" + fib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();
        }

        protected void Button_fib_Con2_on_click(object sender, EventArgs e)
        {
            string fib_no = Label_fib_id2.Text;
            fib_no = fib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_fiber_event_detail set is_show=1 where id=" + fib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();
        }

        protected void Button_fib_Con3_on_click(object sender, EventArgs e)
        {
            string fib_no = Label_fib_id3.Text;
            fib_no = fib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_fiber_event_detail set is_show=1 where id=" + fib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();
        }

        protected void Button_fib_Mis1_on_click(object sender, EventArgs e)
        {
            string fib_no = Label_fib_id1.Text;
            fib_no = fib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_fiber_event_detail set is_show=2 where id=" + fib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();
        }
        protected void Button_fib_Mis2_on_click(object sender, EventArgs e)
        {
            string fib_no = Label_fib_id2.Text;
            fib_no = fib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_fiber_event_detail set is_show=2 where id=" + fib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();

        }
        protected void Button_fib_Mis3_on_click(object sender, EventArgs e)
        {
            string fib_no = Label_fib_id3.Text;
            fib_no = fib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_fiber_event_detail set is_show=2 where id=" + fib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();

        }


        protected void Button_Clear_on_click(object sender, EventArgs e)
        {
            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            db_vib.ExeNoQuery("update hk_show_figure_event set is_show=1;");
            db_vib.Close();
            db_vib.Dispose();

        }

        protected void Button_Restore_on_click(object sender, EventArgs e)
        {
            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            db_vib.ExeNoQuery("update hk_show_figure_event set is_show=0;");
            db_vib.Close();
            db_vib.Dispose();
        }

    }
}