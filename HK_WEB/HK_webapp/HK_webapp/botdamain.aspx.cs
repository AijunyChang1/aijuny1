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
    public partial class botdamain : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            
            string db_ip = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_IP"];
            string db_dsn = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_BOTDA_DSN"];
            string db_user = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_USER"];
            string db_password = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_PW"];
            string db_name = System.Web.Configuration.WebConfigurationManager.AppSettings["DB_BOTDA_NAME"];

            string constr = "dsn=" + db_dsn + ";server=" + db_ip + ";uid=" + db_user + ";database=" + db_name + ";port=3306;pwd=" + db_password;
            OdbcConnection con = new OdbcConnection(constr);
            con.Open();
            string cmd_str = "select id, rece_time, data,  begin_pos, dot_len from hk_botda_data order by id desc limit 1;";
            OdbcCommand com = new OdbcCommand(cmd_str, con);
            OdbcDataReader rd = com.ExecuteReader();
            string r_id;
            string r_data;
            string r_rece_time;
            string r_begin_pos;
            string r_dot_len;

            if (rd.Read())
            {
                r_id = rd["id"].ToString();
                r_data = rd["data"].ToString();
                r_rece_time = rd["rece_time"].ToString();
                r_begin_pos = rd["begin_pos"].ToString();
                r_dot_len = rd["dot_len"].ToString();
                double fiber_pos=Convert.ToDouble(r_begin_pos);
                double fiber_dot_len = Convert.ToDouble(r_dot_len);
                

                int data_pos;
                
                string temp;
                DataTable dt = new DataTable("botda_data");
                dt.Columns.Add(new DataColumn("id", typeof(int)));
                dt.Columns.Add(new DataColumn("rec_time", typeof(string)));
                dt.Columns.Add(new DataColumn("data", typeof(Double)));
                dt.Columns.Add(new DataColumn("position", typeof(string)));
                int t_id = 0;
                string temp_str;
                double local_value_max = 0;
                int id_max = 0;
                double position_max = 0;
                double temp_value = 0;

                while (r_data.Length > 0) 
                {

                    data_pos = r_data.IndexOf(",");
                    if (data_pos > 0)
                    {
                        temp = r_data.Substring(0, data_pos);
                        
                        r_data = r_data.Substring(data_pos + 1);

                    }
                    else 
                    {
                        temp = r_data;
                        r_data = "";
                    }
                    temp_value = Convert.ToDouble(temp);


                    

                   // DataRow d = dt.NewRow();
                    t_id = t_id + 1;
                    fiber_pos = fiber_pos + fiber_dot_len;

                    if (System.Math.Abs(temp_value) > System.Math.Abs(local_value_max))
                    {
                        local_value_max = temp_value;
                        id_max = t_id;
                        position_max = fiber_pos;
                    }

                    if (t_id % 10 == 0)
                    {
                        DataRow dr = dt.NewRow();
                        dr["id"] = id_max;
                        dr["rec_time"] = r_rece_time;
                        dr["data"] = local_value_max;
                        if (position_max == 0)
                        {
                            position_max = fiber_pos;
                        }
                        temp_str = Convert.ToString(position_max);
                        if (temp_str.Length > 8)
                        {
                            temp_str = temp_str.Substring(0, 8);
                        }

                        dr["position"] = temp_str;
                        dt.Rows.Add(dr);
                        local_value_max = 0;
                        position_max = 0;

                    }
 /*                   
                    DataRow dr = dt.NewRow();
                    dr["id"] = t_id;
                    dr["rec_time"] = r_rece_time;
                    dr["data"] =Convert.ToDouble(temp);
                 //   fiber_pos = fiber_pos + fiber_dot_len;
                    temp_str = Convert.ToString(fiber_pos);
                    if (temp_str.Length > 8)
                    {
                        temp_str = temp_str.Substring(0, 8);
                    }
                    dr["position"] = temp_str;
                    dt.Rows.Add(dr);
 */                   

                }
                Label1.Text = r_rece_time;

                /*
                while (t_id < 3)
                {
                    DataRow dr = dt.NewRow();
                    t_id = t_id + 1;
                    dr["id"] = t_id;
                    dr["rec_time"] = r_rece_time;
                    dr["data"] = 8.0+ t_id;
                    fiber_pos = fiber_pos + fiber_dot_len;
                    dr["position"] = Convert.ToString(fiber_pos);
                    dt.Rows.Add(dr);
                }
                */


                Chart1.DataSource = dt;
                Chart1.Series["Series1"].XValueMember = "position";
                Chart1.Series["Series1"].YValueMembers = "data";
                Chart1.Series["Series1"].LegendText = "应变值";
                Chart1.Series["Series1"].IsValueShownAsLabel = false;
                Chart1.DataBind();

                dt.Dispose();

            }





            /*
            string cmd_str = "SELECT case alarm_format when 1 then '定值报警' when 2 then '区域值差' when 3 then '差值报警' when  4 then '故障' when 5 then" +
                    "'故障恢复' else '未知报警' end alarm_format,count(*) total FROM  hk_botda_alarm_info group by alarm_format";

            OdbcCommand com = new OdbcCommand(cmd_str, con);
            // OdbcDataReader rd = com.ExecuteReader();
            OdbcDataAdapter botda_adapter = new OdbcDataAdapter();
            botda_adapter.SelectCommand = com;
            DataSet botda_ds = new DataSet();
            botda_adapter.Fill(botda_ds);
            DataTable botda_dt = botda_ds.Tables[0];
            Chart1.DataSource = botda_ds;
           // Chart1.DataSource = botda_dt;
            Chart1.Series["Series1"].XValueMember = "alarm_format";
            Chart1.Series["Series1"].YValueMembers = "total";
            Chart1.Series["Series1"].LegendText = "alarm_format";
            Chart1.Series["Series1"].IsValueShownAsLabel = true;
            Chart1.DataBind();
            */




           // Chart1.DataBind();
           // Chart1.DataBindTable(rd, "alarm_format");
            rd.Close();
            con.Close();
            con.Dispose();
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            DataBase_Vib db_botda = new DataBase_Vib(2);
            db_botda.Open();
            // OdbcDataReader rd = db_vib.ExecQuerySql("select count(*) c from (select id from hk_vib_event_detail where is_show=0 union select id from  hk_fiber_event_detail where is_show=0) T;");
            DataSet botda_ds = db_botda.ExeQueryToDs("SELECT case alarm_format when 1 then '定值报警' when 2 then '区域值差' when 3 then '差值报警' when  4 then '故障' when 5 then" +
                    "'故障恢复' else '未知报警' end alarm_format,count(*) total FROM  hk_botda_alarm_info group by alarm_format;");

            Chart2.DataSource = botda_ds;
            Chart2.Series["Series1"].XValueMember = "alarm_format";
            Chart2.Series["Series1"].YValueMembers = "total";
           // Chart2.Series["Series1"].LegendText = "alarm_format";
            Chart2.Series["Series1"].IsValueShownAsLabel = true;
            Chart2.DataBind();
            botda_ds.Clear();
            OdbcDataReader rd_time = db_botda.ExecQuerySql("select alarm_time from hk_botda_alarm_info order by id desc limit 1;");
            if (rd_time.Read())
            {
                Label2.Text = rd_time["alarm_time"].ToString();
            }
            rd_time.Close();
            db_botda.Close();
            db_botda.Dispose();


        }

        protected void Timer_main_Tick(object sender, EventArgs e)
        {
            DataBase_Vib db_botda = new DataBase_Vib(2);
            db_botda.Open();
            // OdbcDataReader rd = db_vib.ExecQuerySql("select count(*) c from (select id from hk_vib_event_detail where is_show=0 union select id from  hk_fiber_event_detail where is_show=0) T;");
            OdbcDataReader rd = db_botda.ExecQuerySql("select id, rece_time, data,  begin_pos, dot_len from hk_botda_data order by id desc limit 1;");
            string r_id;
            string r_data;
            string r_rece_time;
            string r_begin_pos;
            string r_dot_len;
            if (rd.Read())
            {
                r_id = rd["id"].ToString();
                r_data = rd["data"].ToString();
                r_rece_time = rd["rece_time"].ToString();
                r_begin_pos = rd["begin_pos"].ToString();
                r_dot_len = rd["dot_len"].ToString();
                double fiber_pos = Convert.ToDouble(r_begin_pos);
                double fiber_dot_len = Convert.ToDouble(r_dot_len);


                int data_pos;

                string temp;
                DataTable dt = new DataTable("botda_data");
                dt.Columns.Add(new DataColumn("id", typeof(int)));
                dt.Columns.Add(new DataColumn("rec_time", typeof(string)));
                dt.Columns.Add(new DataColumn("data", typeof(Double)));
                dt.Columns.Add(new DataColumn("position", typeof(string)));
                int t_id = 0;
                string temp_str;
                double local_value_max = 0;
                int id_max = 0;
                double position_max = 0;
                double temp_value = 0;

                while (r_data.Length > 0)
                {

                    data_pos = r_data.IndexOf(",");
                    if (data_pos > 0)
                    {
                        temp = r_data.Substring(0, data_pos);

                        r_data = r_data.Substring(data_pos + 1);

                    }
                    else
                    {
                        temp = r_data;
                        r_data = "";
                    }
                    temp_value = Convert.ToDouble(temp);




                    // DataRow d = dt.NewRow();
                    t_id = t_id + 1;
                    fiber_pos = fiber_pos + fiber_dot_len;

                    if (System.Math.Abs(temp_value) > System.Math.Abs(local_value_max))
                    {
                        local_value_max = temp_value;
                        id_max = t_id;
                        position_max = fiber_pos;
                    }

                    if (t_id % 10 == 0)
                    {
                        DataRow dr = dt.NewRow();
                        dr["id"] = id_max;
                        dr["rec_time"] = r_rece_time;
                        dr["data"] = local_value_max;
                        if (position_max == 0)
                        {
                            position_max = fiber_pos;
                        }
                        temp_str = Convert.ToString(position_max);
                        if (temp_str.Length > 8)
                        {
                            temp_str = temp_str.Substring(0, 8);
                        }

                        dr["position"] = temp_str;
                        dt.Rows.Add(dr);
                        local_value_max = 0;
                        position_max = 0;

                    }
                    /*                   
                                       DataRow dr = dt.NewRow();
                                       dr["id"] = t_id;
                                       dr["rec_time"] = r_rece_time;
                                       dr["data"] =Convert.ToDouble(temp);
                                    //   fiber_pos = fiber_pos + fiber_dot_len;
                                       temp_str = Convert.ToString(fiber_pos);
                                       if (temp_str.Length > 8)
                                       {
                                           temp_str = temp_str.Substring(0, 8);
                                       }
                                       dr["position"] = temp_str;
                                       dt.Rows.Add(dr);
                    */

                }
                Label1.Text = r_rece_time;

                /*
                while (t_id < 3)
                {
                    DataRow dr = dt.NewRow();
                    t_id = t_id + 1;
                    dr["id"] = t_id;
                    dr["rec_time"] = r_rece_time;
                    dr["data"] = 8.0+ t_id;
                    fiber_pos = fiber_pos + fiber_dot_len;
                    dr["position"] = Convert.ToString(fiber_pos);
                    dt.Rows.Add(dr);
                }
                */


                Chart1.DataSource = dt;
                Chart1.Series["Series1"].XValueMember = "position";
                Chart1.Series["Series1"].YValueMembers = "data";
                Chart1.Series["Series1"].LegendText = "应变值";
                Chart1.Series["Series1"].IsValueShownAsLabel = false;
                Chart1.DataBind();

                dt.Dispose();




            }

            rd.Close();
            db_botda.Close();
            db_botda.Dispose();
            


        }
    }
}