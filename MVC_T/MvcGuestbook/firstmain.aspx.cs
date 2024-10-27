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
    public partial class firstmain : System.Web.UI.Page
    {
        static public string vib_constr;
        static public string vib_select_str;
        protected void Page_Load(object sender, EventArgs e)
        {
            /*
            string db_ip = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_IP"];
            string db_dsn = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_VIB_DSN"];
            string db_user = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_USER"];
            string db_password = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_PW"];
            string db_name = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_VIB_NAME"];
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            vib_constr = "dsn=" + db_dsn + ";server=" + db_ip + ";uid=" + db_user + ";database=" + db_name + ";port=3306;pwd=" + db_password;
            SqlDataSource_vib.ConnectionString = vib_constr;
            if (!IsPostBack)
            {
                vib_select_str = "SELECT  id, channel_id, sensor_id, case fiber_stat when 'Break' then '断纤' when 'NoFiber' " +
                    "then '光纤拔出' when 'None' then '光纤正常' when 'TooLong' then '光纤过长' end fiber_stat, fiber_bk_len, " +
                    "fiber_real_len, push_time, topic,case is_show when 0 then '否' else '是' end show_check FROM  hk_fiber_event_detail order by id desc limit 5000";
            }
            SqlDataSource_vib.SelectCommand = vib_select_str;
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            */
            DataBase_Vib db_vib= new DataBase_Vib(1);
            db_vib.Open();
            // OdbcDataReader rd = db_vib.ExecQuerySql("select count(*) c from (select id from hk_vib_event_detail where is_show=0 union select id from  hk_fiber_event_detail where is_show=0) T;");
            OdbcDataReader rd = db_vib.ExecQuerySql("select count(*) c from (select id from hk_vib_event_detail where is_show=0) T;");
            if (rd.Read())
            {
                Label_vi_total.Text = rd["c"].ToString();
            }

            rd.Close();
            rd = db_vib.ExecQuerySql("select id, push_time, channel_id, center_pos, level from hk_vib_event_detail where is_show=0 order by id desc limit 3;");
            int i = 1;

            while (rd.Read())
            {
                if (i==1)
                {
                   
                    Label_vi_id1.Text = rd["id"].ToString();
                    Label_vi_time1.Text = rd["push_time"].ToString();
                    Label_vi_ch1.Text = rd["channel_id"].ToString();
                    Label_vi_pos1.Text = rd["center_pos"].ToString();
                    Label_vi_level1.Text = rd["level"].ToString();
                    Button_vi1.Visible = true;
                }
                if (i == 2)
                {
                   
                    Label_vi_id2.Text = rd["id"].ToString();
                    Label_vi_time2.Text = rd["push_time"].ToString();
                    Label_vi_ch2.Text = rd["channel_id"].ToString();
                    Label_vi_pos2.Text = rd["center_pos"].ToString();
                    Label_vi_level2.Text = rd["level"].ToString();
                    Button_vi2.Visible = true;
                }
                if (i == 3)
                {
                    
                    Label_vi_id3.Text = rd["id"].ToString();
                    Label_vi_time3.Text = rd["push_time"].ToString();
                    Label_vi_ch3.Text = rd["channel_id"].ToString();
                    Label_vi_pos3.Text = rd["center_pos"].ToString();
                    Label_vi_level3.Text = rd["level"].ToString();
                    Button_vi3.Visible = true;
                }

                i = i + 1;                             

            }

            rd.Close();

            rd = db_vib.ExecQuerySql("select count(*) c from (select id from  hk_fiber_event_detail where is_show=0 and fiber_stat<>'None') T;");
            if (rd.Read())
            {
                Label_fiber_alarm_num.Text = rd["c"].ToString();
            }
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////
            rd.Close();
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
                    Label_fib_status1.Text = rd["fiber_stat"].ToString();
                    Button_fib1.Visible = true;
                }
                if (i == 2)
                {

                    Label_fib_id2.Text = rd["id"].ToString();
                    Label_fib_time2.Text = rd["push_time"].ToString();
                    Label_fib_ch2.Text = rd["channel_id"].ToString();
                    Label_fib_pos2.Text = rd["fiber_bk_len"].ToString();
                    Label_fib_status2.Text = rd["fiber_stat"].ToString();
                    Button_fib2.Visible = true;
                }
                if (i == 3)
                {

                    Label_fib_id3.Text = rd["id"].ToString();
                    Label_fib_time3.Text = rd["push_time"].ToString();
                    Label_fib_ch3.Text = rd["channel_id"].ToString();
                    Label_fib_pos3.Text = rd["fiber_bk_len"].ToString();
                    Label_fib_status3.Text = rd["fiber_stat"].ToString();
                    Button_fib3.Visible = true;
                }

                i = i + 1;

            }

            rd.Close();
            db_vib.Close();
            db_vib.Dispose();
            //////////////////////////////////////////////////////////////////////////////////////
            DataBase_Vib db_botda = new DataBase_Vib(2);
            db_botda.Open();

            rd = db_botda.ExecQuerySql("select count(*) c from (select id from  hk_botda_alarm_info where is_show=0) T;");
            if (rd.Read())
            {
                Label_botda_alarm_num.Text = rd["c"].ToString();
            }

            rd.Close();



            rd = db_botda.ExecQuerySql("select id, alarm_time, channel_id, cent_pos, max_value from hk_botda_alarm_info where is_show=0 order by id desc limit 3;");
            i = 1;


            while (rd.Read())
            {
                if (i == 1)
                {

                    Label_botda_id1.Text = rd["id"].ToString();
                    Label_botda_time1.Text = rd["alarm_time"].ToString();
                    Label_botda_ch1.Text = rd["channel_id"].ToString();
                    Label_botda_pos1.Text = rd["cent_pos"].ToString().Substring(0,8);
                    Label_botda_value1.Text = rd["max_value"].ToString().Substring(0,8);
                    Button_botda1.Visible = true;
                }
                if (i == 2)
                {

                    Label_botda_id2.Text = rd["id"].ToString();
                    Label_botda_time2.Text = rd["alarm_time"].ToString();
                    Label_botda_ch2.Text = rd["channel_id"].ToString();
                    Label_botda_pos2.Text = rd["cent_pos"].ToString().Substring(0,8);
                    Label_botda_value2.Text = rd["max_value"].ToString().Substring(0,8);
                    Button_botda2.Visible = true;
                }
                if (i == 3)
                {

                    Label_botda_id3.Text = rd["id"].ToString();
                    Label_botda_time3.Text = rd["alarm_time"].ToString();
                    Label_botda_ch3.Text = rd["channel_id"].ToString();
                    Label_botda_pos3.Text = rd["cent_pos"].ToString().Substring(0, 8);
                    Label_botda_value3.Text = rd["max_value"].ToString().Substring(0, 8);
                    Button_botda3.Visible = true;
                }

                i = i + 1;

            }

            rd.Close();




            ////////////////////////////////////////////////////////////////////////////////////////////////////////


            rd.Close();
            db_botda.Close();
            db_botda.Dispose();
            if (!IsPostBack)
            {
                Panel_vib_detail.Visible = false;
                Panel_fiber_detail.Visible = false;
                Panel_botda_detail.Visible = false;
                Panel_main_img.Visible = true;
            }

        }

        protected void Link_vi1_OnClick(object sender, EventArgs e)
        {
            Button_vi1.ForeColor = System.Drawing.Color.Red;
            Button_vi2.ForeColor = System.Drawing.Color.Blue;
            Button_vi3.ForeColor = System.Drawing.Color.Blue;
            Button_fib1.ForeColor = System.Drawing.Color.Blue;
            Button_fib2.ForeColor = System.Drawing.Color.Blue;
            Button_fib3.ForeColor = System.Drawing.Color.Blue;
            Button_botda1.ForeColor = System.Drawing.Color.Blue;
            Button_botda2.ForeColor = System.Drawing.Color.Blue;
            Button_botda3.ForeColor = System.Drawing.Color.Blue;
            label_vib_confirm.Visible = false;
            string vi_no = Label_vi_id1.Text;
            vi_no = vi_no.Trim();
            label_vib_head.Text = "振动报警号：" + vi_no;
            
            DataBase_Vib db_vib_detail = new DataBase_Vib(1);
            db_vib_detail.Open();
            string sql_str = "SELECT id, topic," +
                                                            " channel_id, sensor_id, sample_id, " +
                                                            "sample_name, level, possibility, " +
                                                            "center_pos, event_width, max_intensity, " +
                                                            "push_time FROM hk_vib_event_detail where id =" + vi_no ;
            OdbcDataReader rd = db_vib_detail.ExecQuerySql(sql_str);

            if (rd.Read())
            {
                 Label_vib_id_invisable.Text = rd["id"].ToString();
                 Label_vi_de_chid.Text = rd["channel_id"].ToString();
                 Label_vi_de_sampleid.Text= rd["sample_id"].ToString();
                 Label_vi_de_time.Text= rd["push_time"].ToString();
                 Label_vi_de_level.Text = rd["level"].ToString();
                 Label_vi_de_maxi.Text = rd["max_intensity"].ToString();
                 Label_vi_de_pos.Text= rd["center_pos"].ToString();
                 Label_vi_de_width.Text = rd["event_width"].ToString();
                 Label_vi_de_possi.Text = rd["possibility"].ToString();
            }


            rd.Close();
            db_vib_detail.Close();
            db_vib_detail.Dispose();
            Panel_vib_detail.Visible = true;
            Panel_fiber_detail.Visible = false;
            Panel_botda_detail.Visible = false;
            Panel_main_img.Visible = false;

        }

        protected void Link_vi2_OnClick(object sender, EventArgs e)
        {
            Button_vi1.ForeColor = System.Drawing.Color.Blue;
            Button_vi2.ForeColor = System.Drawing.Color.Red;
            Button_vi3.ForeColor = System.Drawing.Color.Blue;
            Button_fib1.ForeColor = System.Drawing.Color.Blue;
            Button_fib2.ForeColor = System.Drawing.Color.Blue;
            Button_fib3.ForeColor = System.Drawing.Color.Blue;
            Button_botda1.ForeColor = System.Drawing.Color.Blue;
            Button_botda2.ForeColor = System.Drawing.Color.Blue;
            Button_botda3.ForeColor = System.Drawing.Color.Blue;
            label_vib_confirm.Visible = false;

            string vi_no = Label_vi_id2.Text;
            vi_no = vi_no.Trim();

            label_vib_head.Text = "振动报警号：" + vi_no;
            DataBase_Vib db_vib_detail = new DataBase_Vib(1);
            db_vib_detail.Open();
            string sql_str = "SELECT hk_vib_event_detail.id, hk_vib_event_detail.topic," +
                                                            " hk_vib_event_detail.channel_id, hk_vib_event_detail.sensor_id, hk_vib_event_detail.sample_id, " +
                                                            "hk_vib_event_detail.sample_name, hk_vib_event_detail.level, hk_vib_event_detail.possibility, " +
                                                            "hk_vib_event_detail.center_pos, hk_vib_event_detail.event_width, hk_vib_event_detail.max_intensity, " +
                                                            "hk_vib_event_detail.push_time, hk_fiber_figure_id.fiber_type, hk_fiber_figure_id.fiber_producer, " +
                                                            "hk_fiber_figure_id.fiber_produce_date, hk_fiber_figure_id.fiber_len, hk_fiber_figure_id.fiber_annotation " +
                                                            "FROM hk_vib_event_detail, hk_fiber_figure_id  where " + "hk_vib_event_detail.id =" + vi_no +
                                                            " and hk_vib_event_detail.channel_id = hk_fiber_figure_id.channel";
            OdbcDataReader rd = db_vib_detail.ExecQuerySql(sql_str);

            if (rd.Read())
            {
                Label_vib_id_invisable.Text = rd["id"].ToString();
                Label_vi_de_chid.Text = rd["channel_id"].ToString();
                Label_vi_de_sampleid.Text = rd["sample_id"].ToString();
                Label_vi_de_time.Text = rd["push_time"].ToString();
                Label_vi_de_level.Text = rd["level"].ToString();
                Label_vi_de_maxi.Text = rd["max_intensity"].ToString();
                Label_vi_de_pos.Text = rd["center_pos"].ToString();
                Label_vi_de_width.Text = rd["event_width"].ToString();

                Label_vi_de_possi.Text = rd["possibility"].ToString();
            }
            rd.Close();
            db_vib_detail.Close();
            db_vib_detail.Dispose();
            Panel_vib_detail.Visible = true;
            Panel_fiber_detail.Visible = false;
            Panel_botda_detail.Visible = false;
            Panel_main_img.Visible = false;
        }
        protected void Link_vi3_OnClick(object sender, EventArgs e)
        {
            Button_vi1.ForeColor = System.Drawing.Color.Blue;
            Button_vi2.ForeColor = System.Drawing.Color.Blue;
            Button_vi3.ForeColor = System.Drawing.Color.Red;
            Button_fib1.ForeColor = System.Drawing.Color.Blue;
            Button_fib2.ForeColor = System.Drawing.Color.Blue;
            Button_fib3.ForeColor = System.Drawing.Color.Blue;
            Button_botda1.ForeColor = System.Drawing.Color.Blue;
            Button_botda2.ForeColor = System.Drawing.Color.Blue;
            Button_botda3.ForeColor = System.Drawing.Color.Blue;
            label_vib_confirm.Visible = false;

            string vi_no = Label_vi_id3.Text;
            vi_no = vi_no.Trim();
            label_vib_head.Text = "振动报警号：" + vi_no;

            DataBase_Vib db_vib_detail = new DataBase_Vib(1);
            db_vib_detail.Open();
            string sql_str = "SELECT hk_vib_event_detail.id, hk_vib_event_detail.topic," +
                                                            " hk_vib_event_detail.channel_id, hk_vib_event_detail.sensor_id, hk_vib_event_detail.sample_id, " +
                                                            "hk_vib_event_detail.sample_name, hk_vib_event_detail.level, hk_vib_event_detail.possibility, " +
                                                            "hk_vib_event_detail.center_pos, hk_vib_event_detail.event_width, hk_vib_event_detail.max_intensity, " +
                                                            "hk_vib_event_detail.push_time, hk_fiber_figure_id.fiber_type, hk_fiber_figure_id.fiber_producer, " +
                                                            "hk_fiber_figure_id.fiber_produce_date, hk_fiber_figure_id.fiber_len, hk_fiber_figure_id.fiber_annotation " +
                                                            "FROM hk_vib_event_detail, hk_fiber_figure_id  where " + "hk_vib_event_detail.id =" + vi_no +
                                                            " and hk_vib_event_detail.channel_id = hk_fiber_figure_id.channel";
            OdbcDataReader rd = db_vib_detail.ExecQuerySql(sql_str);

            if (rd.Read())
            {
                Label_vib_id_invisable.Text = rd["id"].ToString();
                Label_vi_de_chid.Text = rd["channel_id"].ToString();
                Label_vi_de_sampleid.Text = rd["sample_id"].ToString();
                Label_vi_de_time.Text = rd["push_time"].ToString();
                Label_vi_de_level.Text = rd["level"].ToString();
                Label_vi_de_maxi.Text = rd["max_intensity"].ToString();
                Label_vi_de_pos.Text = rd["center_pos"].ToString();
                Label_vi_de_width.Text = rd["event_width"].ToString();

                Label_vi_de_possi.Text = rd["possibility"].ToString();
            }


            rd.Close();
            db_vib_detail.Close();
            db_vib_detail.Dispose();

            Panel_vib_detail.Visible = true;
            Panel_fiber_detail.Visible = false;
            Panel_botda_detail.Visible = false;
            Panel_main_img.Visible = false;
        }        

        protected void Link_fib1_OnClick(object sender, EventArgs e)
        {
            Button_vi1.ForeColor = System.Drawing.Color.Blue;
            Button_vi2.ForeColor = System.Drawing.Color.Blue;
            Button_vi3.ForeColor = System.Drawing.Color.Blue;
            Button_fib1.ForeColor = System.Drawing.Color.Red;
            Button_fib2.ForeColor = System.Drawing.Color.Blue;
            Button_fib3.ForeColor = System.Drawing.Color.Blue;
            Button_botda1.ForeColor = System.Drawing.Color.Blue;
            Button_botda2.ForeColor = System.Drawing.Color.Blue;
            Button_botda3.ForeColor = System.Drawing.Color.Blue;
            label_fib_confirm.Visible = false;
            // Response.Write("<script language='javascript'>document.getElementById('alarm_detail').style.visibility='hidden';</script>");
            // Response.Write("<script type='text/javascript'>alert('Hello!');</script>");

            string fib_no = Label_fib_id1.Text;
            fib_no = fib_no.Trim();

            label_fib_head.Text = "振动光纤状态报警号：" + fib_no;
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "SELECT hk_fiber_event_detail.id, hk_fiber_event_detail.topic," +
                                                            " hk_fiber_event_detail.channel_id, hk_fiber_event_detail.sensor_id, " +
                                                            "hk_fiber_event_detail.fiber_bk_len, case hk_fiber_event_detail.fiber_stat when 'Break' then '断纤' when 'NoFiber' " +
                                                            "then '光纤拔出' when 'None' then '光纤正常' when 'TooLong' then '光纤过长' end fiber_stat, " +
                                                            "hk_fiber_event_detail.push_time, hk_fiber_figure_id.fiber_type, hk_fiber_figure_id.fiber_producer, " +
                                                            "hk_fiber_figure_id.fiber_produce_date, hk_fiber_figure_id.fiber_len, hk_fiber_figure_id.fiber_annotation " +
                                                            "FROM hk_fiber_event_detail, hk_fiber_figure_id  where " + "hk_fiber_event_detail.id =" + fib_no +
                                                            " and hk_fiber_event_detail.channel_id = hk_fiber_figure_id.channel";
            OdbcDataReader rd = db_fib_detail.ExecQuerySql(sql_str);

            if (rd.Read())
            {
                Label_fib_id_invisable.Text = rd["id"].ToString();
                Label_fib_de_chid.Text = rd["channel_id"].ToString();
                Label_fib_de_time.Text = rd["push_time"].ToString();
                Label_fib_de_sta.Text= rd["fiber_stat"].ToString();
                Label_fib_de_pos.Text = rd["fiber_bk_len"].ToString();

                Label_fib_de_fproducer.Text = rd["fiber_producer"].ToString();
                Label_fib_de_ftype.Text = rd["fiber_type"].ToString();
                Label_fib_de_flength.Text = rd["fiber_len"].ToString();
                Label_fib_de_fdate.Text = rd["fiber_produce_date"].ToString();
            }


            rd.Close();
            db_fib_detail.Close();
            db_fib_detail.Dispose();


            Panel_vib_detail.Visible = false;
            Panel_fiber_detail.Visible = true;
            Panel_botda_detail.Visible = false;
            Panel_main_img.Visible = false;

        }
        protected void Link_fib2_OnClick(object sender, EventArgs e)
        {
            Button_vi1.ForeColor = System.Drawing.Color.Blue;
            Button_vi2.ForeColor = System.Drawing.Color.Blue;
            Button_vi3.ForeColor = System.Drawing.Color.Blue;
            Button_fib1.ForeColor = System.Drawing.Color.Blue;
            Button_fib2.ForeColor = System.Drawing.Color.Red;
            Button_fib3.ForeColor = System.Drawing.Color.Blue;
            Button_botda1.ForeColor = System.Drawing.Color.Blue;
            Button_botda2.ForeColor = System.Drawing.Color.Blue;
            Button_botda3.ForeColor = System.Drawing.Color.Blue;
            label_fib_confirm.Visible = false;

            string fib_no = Label_fib_id2.Text;
            fib_no = fib_no.Trim();
            label_fib_head.Text = "振动光纤状态报警号：" + fib_no;
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "SELECT hk_fiber_event_detail.id, hk_fiber_event_detail.topic," +
                                                            " hk_fiber_event_detail.channel_id, hk_fiber_event_detail.sensor_id, " +
                                                            "hk_fiber_event_detail.fiber_bk_len, case hk_fiber_event_detail.fiber_stat when 'Break' then '断纤' when 'NoFiber' " +
                                                            "then '光纤拔出' when 'None' then '光纤正常' when 'TooLong' then '光纤过长' end fiber_stat, " +
                                                            "hk_fiber_event_detail.push_time, hk_fiber_figure_id.fiber_type, hk_fiber_figure_id.fiber_producer, " +
                                                            "hk_fiber_figure_id.fiber_produce_date, hk_fiber_figure_id.fiber_len, hk_fiber_figure_id.fiber_annotation " +
                                                            "FROM hk_fiber_event_detail, hk_fiber_figure_id  where " + "hk_fiber_event_detail.id =" + fib_no +
                                                            " and hk_fiber_event_detail.channel_id = hk_fiber_figure_id.channel";
            OdbcDataReader rd = db_fib_detail.ExecQuerySql(sql_str);

            if (rd.Read())
            {
                Label_fib_id_invisable.Text = rd["id"].ToString();
                Label_fib_de_chid.Text = rd["channel_id"].ToString();
                Label_fib_de_time.Text = rd["push_time"].ToString();
                Label_fib_de_sta.Text = rd["fiber_stat"].ToString();
                Label_fib_de_pos.Text = rd["fiber_bk_len"].ToString();

                Label_fib_de_fproducer.Text = rd["fiber_producer"].ToString();
                Label_fib_de_ftype.Text = rd["fiber_type"].ToString();
                Label_fib_de_flength.Text = rd["fiber_len"].ToString();
                Label_fib_de_fdate.Text = rd["fiber_produce_date"].ToString();
            }


            rd.Close();
            db_fib_detail.Close();
            db_fib_detail.Dispose();


            Panel_vib_detail.Visible = false;
            Panel_fiber_detail.Visible = true;
            Panel_botda_detail.Visible = false;
            Panel_main_img.Visible = false;

        }

        protected void Link_fib3_OnClick(object sender, EventArgs e)
        {
            Button_vi1.ForeColor = System.Drawing.Color.Blue;
            Button_vi2.ForeColor = System.Drawing.Color.Blue;
            Button_vi3.ForeColor = System.Drawing.Color.Blue;
            Button_fib1.ForeColor = System.Drawing.Color.Blue;
            Button_fib2.ForeColor = System.Drawing.Color.Blue;
            Button_fib3.ForeColor = System.Drawing.Color.Red;
            Button_botda1.ForeColor = System.Drawing.Color.Blue;
            Button_botda2.ForeColor = System.Drawing.Color.Blue;
            Button_botda3.ForeColor = System.Drawing.Color.Blue;

            label_fib_confirm.Visible = false;
            string fib_no = Label_fib_id3.Text;
            fib_no = fib_no.Trim();
            label_fib_head.Text = "振动光纤状态报警号：" + fib_no;
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "SELECT hk_fiber_event_detail.id, hk_fiber_event_detail.topic," +
                                                            " hk_fiber_event_detail.channel_id, hk_fiber_event_detail.sensor_id, " +
                                                            "hk_fiber_event_detail.fiber_bk_len, case hk_fiber_event_detail.fiber_stat when 'Break' then '断纤' when 'NoFiber' " +
                                                            "then '光纤拔出' when 'None' then '光纤正常' when 'TooLong' then '光纤过长' end fiber_stat, " +
                                                            "hk_fiber_event_detail.push_time, hk_fiber_figure_id.fiber_type, hk_fiber_figure_id.fiber_producer, " +
                                                            "hk_fiber_figure_id.fiber_produce_date, hk_fiber_figure_id.fiber_len, hk_fiber_figure_id.fiber_annotation " +
                                                            "FROM hk_fiber_event_detail, hk_fiber_figure_id  where " + "hk_fiber_event_detail.id =" + fib_no +
                                                            " and hk_fiber_event_detail.channel_id = hk_fiber_figure_id.channel";
            OdbcDataReader rd = db_fib_detail.ExecQuerySql(sql_str);

            if (rd.Read())
            {
                Label_fib_id_invisable.Text = rd["id"].ToString();
                Label_fib_de_chid.Text = rd["channel_id"].ToString();
                Label_fib_de_time.Text = rd["push_time"].ToString();
                Label_fib_de_sta.Text = rd["fiber_stat"].ToString();
                Label_fib_de_pos.Text = rd["fiber_bk_len"].ToString();

                Label_fib_de_fproducer.Text = rd["fiber_producer"].ToString();
                Label_fib_de_ftype.Text = rd["fiber_type"].ToString();
                Label_fib_de_flength.Text = rd["fiber_len"].ToString();
                Label_fib_de_fdate.Text = rd["fiber_produce_date"].ToString();
            }


            rd.Close();
            db_fib_detail.Close();
            db_fib_detail.Dispose();

            Panel_vib_detail.Visible = false;
            Panel_fiber_detail.Visible = true;
            Panel_botda_detail.Visible = false;
            Panel_main_img.Visible = false;

        }

        //==================================================================================
        protected void Link_bodta1_OnClick(object sender, EventArgs e)
        {
            Button_vi1.ForeColor = System.Drawing.Color.Blue;
            Button_vi2.ForeColor = System.Drawing.Color.Blue;
            Button_vi3.ForeColor = System.Drawing.Color.Blue;
            Button_fib1.ForeColor = System.Drawing.Color.Blue;
            Button_fib2.ForeColor = System.Drawing.Color.Blue;
            Button_fib3.ForeColor = System.Drawing.Color.Blue;
            Button_botda1.ForeColor = System.Drawing.Color.Red;
            Button_botda2.ForeColor = System.Drawing.Color.Blue;
            Button_botda3.ForeColor = System.Drawing.Color.Blue;

            label_botda_confirm.Visible = false;
            string botda_no = Label_botda_id1.Text;
            botda_no = botda_no.Trim();

            label_botda_head.Text = "BOTDA报警号：" + botda_no;
            DataBase_Vib db_botda_detail = new DataBase_Vib(2);
            db_botda_detail.Open();
            string sql_str = "SELECT id, device_name, channel_id, alarm_time,update_time,event_type,alarm_guid, max_value,limen_value, case alarm_format when 1 then '定值报警' when 2 then '定值报警' when 3 then '差值报警' when  4 then '故障' when 5 then" +
                "'故障恢复' else '未知报警' end alarm_type, begin_pos, end_pos, cent_pos from hk_botda_alarm_info where id="+ botda_no;
            OdbcDataReader rd = db_botda_detail.ExecQuerySql(sql_str);

            if (rd.Read())
            {
                Label_botda_id_invisable.Text = rd["id"].ToString();
                Label_botda_de_chid.Text = rd["channel_id"].ToString();
                Label_botda_de_time.Text = rd["alarm_time"].ToString();
                string start_pos_str = rd["begin_pos"].ToString();
                if (start_pos_str.Length > 8)
                {
                    Label_botda_de_start_pos.Text = rd["begin_pos"].ToString().Substring(0, 8);
                }
                else
                {
                    Label_botda_de_start_pos.Text = start_pos_str;
                }

                string end_pos_str = rd["end_pos"].ToString();
                if (end_pos_str.Length > 8)
                {
                    Label_botda_de_end_pos.Text = rd["end_pos"].ToString().Substring(0, 8);
                }
                else 
                {
                    Label_botda_de_end_pos.Text = end_pos_str;
                }
                string cent_pos_str = rd["cent_pos"].ToString();
                if (cent_pos_str.Length > 8)
                {
                    Label_botda_de_cent_pos.Text = rd["cent_pos"].ToString().Substring(0, 8);
                }
                else
                {
                    Label_botda_de_cent_pos.Text = cent_pos_str;
                }

                Label_botda_de_alarm_type.Text = rd["alarm_type"].ToString();
                Label_botda_max_value.Text = rd["max_value"].ToString().Substring(0, 8);
                Label_botda_limit_value.Text = rd["limen_value"].ToString();
          
            }


            rd.Close();
            db_botda_detail.Close();
            db_botda_detail.Dispose();



            Panel_main_img.Visible = false;
            Panel_vib_detail.Visible = false;
            Panel_fiber_detail.Visible = false;
            Panel_botda_detail.Visible = true;


        }
        protected void Link_bodta2_OnClick(object sender, EventArgs e)
        {
            Button_vi1.ForeColor = System.Drawing.Color.Blue;
            Button_vi2.ForeColor = System.Drawing.Color.Blue;
            Button_vi3.ForeColor = System.Drawing.Color.Blue;
            Button_fib1.ForeColor = System.Drawing.Color.Blue;
            Button_fib2.ForeColor = System.Drawing.Color.Blue;
            Button_fib3.ForeColor = System.Drawing.Color.Blue;
            Button_botda1.ForeColor = System.Drawing.Color.Blue;
            Button_botda2.ForeColor = System.Drawing.Color.Red;
            Button_botda3.ForeColor = System.Drawing.Color.Blue;

            label_botda_confirm.Visible = false;
            string botda_no = Label_botda_id2.Text;
            botda_no = botda_no.Trim();

            label_botda_head.Text = "BOTDA报警号：" + botda_no;
            DataBase_Vib db_botda_detail = new DataBase_Vib(2);
            db_botda_detail.Open();
            string sql_str = "SELECT id, device_name, channel_id, alarm_time,update_time,event_type,alarm_guid, max_value,limen_value, case alarm_format when 1 then '定值报警' when 2 then '区域值差' when 3 then '差值报警' when  4 then '故障' when 5 then" +
                "'故障恢复' else '未知报警' end alarm_type, begin_pos, end_pos, cent_pos from hk_botda_alarm_info where id=" + botda_no;
            OdbcDataReader rd = db_botda_detail.ExecQuerySql(sql_str);

            if (rd.Read())
            {
                Label_botda_id_invisable.Text = rd["id"].ToString();
                Label_botda_de_chid.Text = rd["channel_id"].ToString();
                Label_botda_de_time.Text = rd["alarm_time"].ToString();
                // Label_botda_de_start_pos.Text = rd["begin_pos"].ToString().Substring(0, 8);
                //Label_botda_de_end_pos.Text = rd["end_pos"].ToString().Substring(0, 8);
                //Label_botda_de_cent_pos.Text = rd["cent_pos"].ToString().Substring(0, 8);
                string start_pos_str = rd["begin_pos"].ToString();
                if (start_pos_str.Length > 8)
                {
                    Label_botda_de_start_pos.Text = rd["begin_pos"].ToString().Substring(0, 8);
                }
                else
                {
                    Label_botda_de_start_pos.Text = start_pos_str;
                }

                string end_pos_str = rd["end_pos"].ToString();
                if (end_pos_str.Length > 8)
                {
                    Label_botda_de_end_pos.Text = rd["end_pos"].ToString().Substring(0, 8);
                }
                else
                {
                    Label_botda_de_end_pos.Text = end_pos_str;
                }
                string cent_pos_str = rd["cent_pos"].ToString();
                if (cent_pos_str.Length > 8)
                {
                    Label_botda_de_cent_pos.Text = rd["cent_pos"].ToString().Substring(0, 8);
                }
                else
                {
                    Label_botda_de_cent_pos.Text = cent_pos_str;
                }

                Label_botda_de_alarm_type.Text = rd["alarm_type"].ToString();
                Label_botda_max_value.Text = rd["max_value"].ToString().Substring(0, 8);
                Label_botda_limit_value.Text = rd["limen_value"].ToString();

            }


            rd.Close();
            db_botda_detail.Close();
            db_botda_detail.Dispose();

            Panel_main_img.Visible = false;
            Panel_vib_detail.Visible = false;
            Panel_fiber_detail.Visible = false;
            Panel_botda_detail.Visible = true;

        }

        protected void Link_botda3_OnClick(object sender, EventArgs e)
        {
            Button_vi1.ForeColor = System.Drawing.Color.Blue;
            Button_vi2.ForeColor = System.Drawing.Color.Blue;
            Button_vi3.ForeColor = System.Drawing.Color.Blue;
            Button_fib1.ForeColor = System.Drawing.Color.Blue;
            Button_fib2.ForeColor = System.Drawing.Color.Blue;
            Button_fib3.ForeColor = System.Drawing.Color.Blue;
            Button_botda1.ForeColor = System.Drawing.Color.Blue;
            Button_botda2.ForeColor = System.Drawing.Color.Blue;
            Button_botda3.ForeColor = System.Drawing.Color.Red;

            label_botda_confirm.Visible = false;
            string botda_no = Label_botda_id3.Text;
            botda_no = botda_no.Trim();

            label_botda_head.Text = "BOTDA报警号：" + botda_no;
            DataBase_Vib db_botda_detail = new DataBase_Vib(2);
            db_botda_detail.Open();
            string sql_str = "SELECT id, device_name, channel_id, alarm_time,update_time,event_type,alarm_guid, max_value,limen_value, case alarm_format when 1 then '定值报警' when 2 then '定值报警' when 3 then '差值报警' when  4 then '故障' when 5 then" +
                "'故障恢复' else '未知报警' end alarm_type, begin_pos, end_pos, cent_pos from hk_botda_alarm_info where id=" + botda_no;
            OdbcDataReader rd = db_botda_detail.ExecQuerySql(sql_str);

            if (rd.Read())
            {
                Label_botda_id_invisable.Text = rd["id"].ToString();
                Label_botda_de_chid.Text = rd["channel_id"].ToString();
                Label_botda_de_time.Text = rd["alarm_time"].ToString();
                // Label_botda_de_start_pos.Text = rd["begin_pos"].ToString().Substring(0, 8);
                // Label_botda_de_end_pos.Text = rd["end_pos"].ToString().Substring(0, 8);
                //  Label_botda_de_cent_pos.Text = rd["cent_pos"].ToString().Substring(0, 8);
                string start_pos_str = rd["begin_pos"].ToString();
                if (start_pos_str.Length > 8)
                {
                    Label_botda_de_start_pos.Text = rd["begin_pos"].ToString().Substring(0, 8);
                }
                else
                {
                    Label_botda_de_start_pos.Text = start_pos_str;
                }

                string end_pos_str = rd["end_pos"].ToString();
                if (end_pos_str.Length > 8)
                {
                    Label_botda_de_end_pos.Text = rd["end_pos"].ToString().Substring(0, 8);
                }
                else
                {
                    Label_botda_de_end_pos.Text = end_pos_str;
                }
                string cent_pos_str = rd["cent_pos"].ToString();
                if (cent_pos_str.Length > 8)
                {
                    Label_botda_de_cent_pos.Text = rd["cent_pos"].ToString().Substring(0, 8);
                }
                else
                {
                    Label_botda_de_cent_pos.Text = cent_pos_str;
                }
                Label_botda_de_alarm_type.Text = rd["alarm_type"].ToString();
                Label_botda_max_value.Text = rd["max_value"].ToString().Substring(0, 8);
                Label_botda_limit_value.Text = rd["limen_value"].ToString();

            }


            rd.Close();
            db_botda_detail.Close();
            db_botda_detail.Dispose();




            Panel_main_img.Visible = false;
            Panel_vib_detail.Visible = false;
            Panel_fiber_detail.Visible = false;
            Panel_botda_detail.Visible = true;

        }



        //===========================================================================================
        protected void Button_vib_confirm_Click(object sender, EventArgs e)
        {

            string vib_no = Label_vib_id_invisable.Text;
            vib_no = vib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_vib_event_detail set is_show=1 where id=" + vib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();
            label_vib_confirm.Text = "(已确认)";
            label_vib_confirm.ForeColor = System.Drawing.Color.Red;
            label_vib_confirm.Visible = true;
            Button_vi1.ForeColor = System.Drawing.Color.Blue;
            Button_vi2.ForeColor = System.Drawing.Color.Blue;
            Button_vi3.ForeColor = System.Drawing.Color.Blue;

        }
        protected void Button_vib_misalarm_Click(object sender, EventArgs e)
        {
            string vib_no = Label_vib_id_invisable.Text;
            vib_no = vib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_vib_event_detail set is_show=2 where id=" + vib_no+";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();
            label_vib_confirm.Text = "(确认为误报)";
            label_vib_confirm.ForeColor = System.Drawing.Color.Green;
            label_vib_confirm.Visible = true;
            Button_vi1.ForeColor = System.Drawing.Color.Blue;
            Button_vi2.ForeColor = System.Drawing.Color.Blue;
            Button_vi3.ForeColor = System.Drawing.Color.Blue;


        }
        protected void Button_fib_confirm_Click(object sender, EventArgs e)
        {
            string fib_no = Label_fib_id_invisable.Text;
            fib_no = fib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_fiber_event_detail set is_show=1 where id=" + fib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();
            label_fib_confirm.Text = "(已确认)";
            label_fib_confirm.ForeColor = System.Drawing.Color.Red;
            label_fib_confirm.Visible = true;
            Button_fib1.ForeColor = System.Drawing.Color.Blue;
            Button_fib2.ForeColor = System.Drawing.Color.Blue;
            Button_fib3.ForeColor = System.Drawing.Color.Blue;
        }

        protected void Button_fib_misalarm_Click(object sender, EventArgs e)
        {
            string fib_no = Label_fib_id_invisable.Text;
            fib_no = fib_no.Trim();
            DataBase_Vib db_fib_detail = new DataBase_Vib(1);
            db_fib_detail.Open();
            string sql_str = "update hk_fiber_event_detail set is_show=2 where id=" + fib_no + ";";
            db_fib_detail.ExeNoQuery(sql_str);
            db_fib_detail.Close();
            db_fib_detail.Dispose();
            label_fib_confirm.Text = "(确认为误报)";
            label_fib_confirm.ForeColor = System.Drawing.Color.Green;
            label_fib_confirm.Visible = true;
            Button_fib1.ForeColor = System.Drawing.Color.Blue;
            Button_fib2.ForeColor = System.Drawing.Color.Blue;
            Button_fib3.ForeColor = System.Drawing.Color.Blue;


        }
        protected void Button_botda_confirm_Click(object sender, EventArgs e)
        {
            string botda_no = Label_botda_id_invisable.Text;
            botda_no = botda_no.Trim();
            DataBase_Vib db_botda_detail = new DataBase_Vib(2);
            db_botda_detail.Open();
            string sql_str = "update hk_botda_alarm_info set is_show=1 where id=" + botda_no + ";";
            db_botda_detail.ExeNoQuery(sql_str);
            db_botda_detail.Close();
            db_botda_detail.Dispose();
            label_botda_confirm.Text = "(已确认)";
            label_botda_confirm.ForeColor = System.Drawing.Color.Red;
            label_botda_confirm.Visible = true;
            Button_botda1.ForeColor = System.Drawing.Color.Blue;
            Button_botda2.ForeColor = System.Drawing.Color.Blue;
            Button_botda3.ForeColor = System.Drawing.Color.Blue;

        }
        protected void Button_botda_misalarm_Click(object sender, EventArgs e)
        {

            string botda_no = Label_botda_id_invisable.Text;
            botda_no = botda_no.Trim();
            DataBase_Vib db_botda_detail = new DataBase_Vib(2);
            db_botda_detail.Open();
            string sql_str = "update hk_botda_alarm_info set is_show=2 where id=" + botda_no + ";";
            db_botda_detail.ExeNoQuery(sql_str);
            db_botda_detail.Close();
            db_botda_detail.Dispose();
            label_botda_confirm.Text = "(确认为误报)";
            label_botda_confirm.ForeColor = System.Drawing.Color.Green;
            label_botda_confirm.Visible = true;
            Button_botda1.ForeColor = System.Drawing.Color.Blue;
            Button_botda2.ForeColor = System.Drawing.Color.Blue;
            Button_botda3.ForeColor = System.Drawing.Color.Blue;



        }

        protected void Timer_main_Tick(object sender, EventArgs e)
        {
            Label_vi_id1.Text = "";
            Label_vi_id2.Text = "";
            Label_vi_id3.Text = "";
            Label_vi_time1.Text = "";
            Label_vi_time2.Text = "";
            Label_vi_time3.Text = "";
            Label_vi_ch1.Text = "";
            Label_vi_ch2.Text = "";
            Label_vi_ch3.Text = "";
            Label_vi_pos1.Text = "";
            Label_vi_pos2.Text = "";
            Label_vi_pos3.Text = "";
            Label_vi_level1.Text = "";
            Label_vi_level2.Text = "";
            Label_vi_level3.Text = "";

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
            Label_fib_status1.Text = "";
            Label_fib_status2.Text = "";
            Label_fib_status3.Text = "";
            Button_vi1.Visible = false;
            Button_vi2.Visible = false;
            Button_vi3.Visible = false;
            Button_fib1.Visible = false;
            Button_fib2.Visible = false;
            Button_fib3.Visible = false;

            DataBase_Vib db_vib = new DataBase_Vib(1);
            db_vib.Open();
            // OdbcDataReader rd = db_vib.ExecQuerySql("select count(*) c from (select id from hk_vib_event_detail where is_show=0 union select id from  hk_fiber_event_detail where is_show=0) T;");
            OdbcDataReader rd = db_vib.ExecQuerySql("select count(*) c from (select id from hk_vib_event_detail where is_show=0) T;");
            if (rd.Read())
            {
                Label_vi_total.Text = rd["c"].ToString();
            }

            rd.Close();
            rd = db_vib.ExecQuerySql("select id, push_time, channel_id, center_pos, level from hk_vib_event_detail where is_show=0 order by id desc limit 3;");
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
                    Button_vi1.Visible = true;
                }
                if (i == 2)
                {

                    Label_vi_id2.Text = rd["id"].ToString();
                    Label_vi_time2.Text = rd["push_time"].ToString();
                    Label_vi_ch2.Text = rd["channel_id"].ToString();
                    Label_vi_pos2.Text = rd["center_pos"].ToString();
                    Label_vi_level2.Text = rd["level"].ToString();
                    Button_vi2.Visible = true;
                }
                if (i == 3)
                {

                    Label_vi_id3.Text = rd["id"].ToString();
                    Label_vi_time3.Text = rd["push_time"].ToString();
                    Label_vi_ch3.Text = rd["channel_id"].ToString();
                    Label_vi_pos3.Text = rd["center_pos"].ToString();
                    Label_vi_level3.Text = rd["level"].ToString();
                    Button_vi3.Visible = true;
                }

                i = i + 1;

            }

            rd.Close();

            rd = db_vib.ExecQuerySql("select count(*) c from (select id from  hk_fiber_event_detail where is_show=0 and fiber_stat<>'None') T;");
            if (rd.Read())
            {
                Label_fiber_alarm_num.Text = rd["c"].ToString();
            }
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////
            rd.Close();
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
                    Label_fib_status1.Text = rd["fiber_stat"].ToString();
                    Button_fib1.Visible = true;
                }
                if (i == 2)
                {

                    Label_fib_id2.Text = rd["id"].ToString();
                    Label_fib_time2.Text = rd["push_time"].ToString();
                    Label_fib_ch2.Text = rd["channel_id"].ToString();
                    Label_fib_pos2.Text = rd["fiber_bk_len"].ToString();
                    Label_fib_status2.Text = rd["fiber_stat"].ToString();
                    Button_fib2.Visible = true;
                }
                if (i == 3)
                {

                    Label_fib_id3.Text = rd["id"].ToString();
                    Label_fib_time3.Text = rd["push_time"].ToString();
                    Label_fib_ch3.Text = rd["channel_id"].ToString();
                    Label_fib_pos3.Text = rd["fiber_bk_len"].ToString();
                    Label_fib_status3.Text = rd["fiber_stat"].ToString();
                    Button_fib3.Visible = true;
                }

                i = i + 1;

            }

            rd.Close();
            db_vib.Close();
            db_vib.Dispose();


            //////////////////////////////////////////////////////////////////////////////////////
            DataBase_Vib db_botda = new DataBase_Vib(2);
            db_botda.Open();

            rd = db_botda.ExecQuerySql("select count(*) c from (select id from  hk_botda_alarm_info where is_show=0) T;");
            if (rd.Read())
            {
                Label_botda_alarm_num.Text = rd["c"].ToString();
            }

            rd.Close();



            rd = db_botda.ExecQuerySql("select id, alarm_time, channel_id, cent_pos, max_value from hk_botda_alarm_info where is_show=0 order by id desc limit 3;");
            i = 1;


            while (rd.Read())
            {
                if (i == 1)
                {

                    Label_botda_id1.Text = rd["id"].ToString();
                    Label_botda_time1.Text = rd["alarm_time"].ToString();
                    Label_botda_ch1.Text = rd["channel_id"].ToString();
                    Label_botda_pos1.Text = rd["cent_pos"].ToString().Substring(0, 8);
                    Label_botda_value1.Text = rd["max_value"].ToString().Substring(0, 8);
                    Button_botda1.Visible = true;
                }
                if (i == 2)
                {

                    Label_botda_id2.Text = rd["id"].ToString();
                    Label_botda_time2.Text = rd["alarm_time"].ToString();
                    Label_botda_ch2.Text = rd["channel_id"].ToString();
                    Label_botda_pos2.Text = rd["cent_pos"].ToString().Substring(0, 8);
                    Label_botda_value2.Text = rd["max_value"].ToString().Substring(0, 8);
                    Button_botda2.Visible = true;
                }
                if (i == 3)
                {

                    Label_botda_id3.Text = rd["id"].ToString();
                    Label_botda_time3.Text = rd["alarm_time"].ToString();
                    Label_botda_ch3.Text = rd["channel_id"].ToString();
                    Label_botda_pos3.Text = rd["cent_pos"].ToString().Substring(0, 8);
                    Label_botda_value3.Text = rd["max_value"].ToString().Substring(0, 8);
                    Button_botda3.Visible = true;
                }

                i = i + 1;

            }

            rd.Close();




            ////////////////////////////////////////////////////////////////////////////////////////////////////////


            rd.Close();
            db_botda.Close();
            db_botda.Dispose();


        }


    }
}