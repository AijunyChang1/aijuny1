#include "stdafx.h"
//#include "socket.h"
#include <stdio.h>
#include "encode.h"
#include "decode.h"


void decode_msg(char *msgbuf, int len,RecvInfo* Param)
{

		RecvInfo* P=(RecvInfo*)Param;
	  //  int len=P->RecvLen;
	    RecvSendInfo*Ps=P->SockInfo;
       if (msgbuf != NULL && len > 0) {

//        m_last_event_time.refresh();
        unsigned char *p = msgbuf;
        int body_len = decode_uint_msg(&p, len);
        int msgtype = decode_uint_msg(&p, len);

		char a[30];
		sprintf(a,"%d",msgtype);
	//	MessageBoxA(NULL,a,"test",1);
        #ifdef WRITE_HEARTBEAT_LOG
        if (msgtype == HEARTBEAT_CONF) {
//            write_msg_log("Evt", msgtype, "body length:%d", body_len);
        }
        #endif
        if (msgtype != HEARTBEAT_CONF) {
//            write_msg_log("Evt", msgtype, "body length:%d", body_len);
        }


        switch (msgtype) {
			case OPEN_REQ:        on_open_conf(p,Param);     break;   //=3
			case HEARTBEAT_REQ:   on_heartbeat_conf(p,Param);break;   //=5
			case CLOSE_REQ:       on_close_conf(p,Param);    break;   //=7

			case QUERY_DEVICE_INFO_REQ: 
				                  on_query_device_info_conf(p, Param); break;
			case QUERY_AGENT_STATE_REQ:  on_query_agent_state_conf(p, Param); break ; 

			case SET_AGENT_STATE_REQ: on_set_agent_state_conf(p, Param); break ;

            // null msg
	        //case NULL_MSG					  : //	= 0,
            //    break;
            // confirmation msg
		/*		      
		   case FAILURE_CONF				  : //	= 1,
	            on_failure_conf(msgtype, p, body_len, sender);
                break;	
 
	        case OPEN_CONF					  : //	= 4,
	            on_open_conf(msgtype, p, body_len, sender);
                break;
	        case HEARTBEAT_CONF				  : //	= 6,
	            on_heartbeat_conf(msgtype, p, body_len, sender);
                break;
	        case CLOSE_CONF					  : //	= 8,
	            on_close_conf(msgtype, p, body_len, sender);
                break;
	        case SET_CALL_DATA_CONF			  : //	= 27,
	            on_set_call_data_conf(msgtype, p, body_len, sender);
                break;
	        case RELEASE_CALL_CONF			  : //	= 29,
	            on_release_call_conf(msgtype, p, body_len, sender);
                break;
	        case CLIENT_EVENT_REPORT_CONF	  : //	= 33,
	            on_client_event_report_conf(msgtype, p, body_len, sender);
                break;
	        case CONTROL_FAILURE_CONF		  : //	= 35,
	            on_control_failure_conf(msgtype, p, body_len, sender);
                break;
	        case QUERY_AGENT_STATE_CONF		  : //	= 37,
	            on_query_agent_state_conf(msgtype, p, body_len, sender);
                break;
	        case SET_AGENT_STATE_CONF		  : //	= 39,
	            on_set_agent_state_conf(msgtype, p, body_len, sender);
                break;
	        case ALTERNATE_CALL_CONF		  : //	= 41,
	            on_alternate_call_conf(msgtype, p, body_len, sender);
                break;
	        case ANSWER_CALL_CONF			  : //	= 43,
	            on_answer_call_conf(msgtype, p, body_len, sender);
                break;
	        case CLEAR_CALL_CONF			  : //	= 45,
	            on_clear_call_conf(msgtype, p, body_len, sender);
                break;
	        case CLEAR_CONNECTION_CONF		  : //	= 47,
	            on_clear_connection_conf(msgtype, p, body_len, sender);
                break;
	        case CONFERENCE_CALL_CONF		  : //	= 49,
	            on_conference_call_conf(msgtype, p, body_len, sender);
                break;
	        case CONSULTATION_CALL_CONF		  : //	= 51,
	            on_consultation_call_conf(msgtype, p, body_len, sender);
                break;
	        case DEFLECT_CALL_CONF			  : //	= 53,
	            on_deflect_call_conf(msgtype, p, body_len, sender);
                break;
	        case HOLD_CALL_CONF				  : //	= 55,
	            on_hold_call_conf(msgtype, p, body_len, sender);
                break;
	        case MAKE_CALL_CONF				  : //	= 57,
	            on_make_call_conf(msgtype, p, body_len, sender);
                break;
	        case MAKE_PREDICTIVE_CALL_CONF	  : //	= 59,
	            on_make_predictive_call_conf(msgtype, p, body_len, sender);
                break;
	        case RECONNECT_CALL_CONF		  : //	= 61,
	            on_reconnect_call_conf(msgtype, p, body_len, sender);
                break;
	        case RETRIEVE_CALL_CONF			  : //	= 63,
	            on_retrieve_call_conf(msgtype, p, body_len, sender);
                break;
	        case TRANSFER_CALL_CONF			  : //	= 65,
	            on_transfer_call_conf(msgtype, p, body_len, sender);
                break;
	        case QUERY_MSG_WAITING_IND_CONF	  : //	= 67,
	            on_query_msg_waiting_ind_conf(msgtype, p, body_len, sender);
                break;
	        case SET_MSG_WAITING_IND_CONF	  : //	= 69,
	            on_set_msg_waiting_ind_conf(msgtype, p, body_len, sender);
                break;
	        case QUERY_DO_NOT_DISTURB_CONF	  : //	= 71,
	            on_query_do_not_disturb_conf(msgtype, p, body_len, sender);
                break;
	        case SET_DO_NOT_DISTURB_CONF	  : //	= 73,
	            on_set_do_not_disturb_conf(msgtype, p, body_len, sender);
                break;
	        case QUERY_FORWARDING_CONF		  : //	= 75,
	            on_query_forwarding_conf(msgtype, p, body_len, sender);
                break;
	        case SET_FORWARDING_CONF		  : //	= 77,
	            on_set_forwarding_conf(msgtype, p, body_len, sender);
                break;
	        case QUERY_DEVICE_INFO_CONF		  : //	= 79,
	            on_query_device_info_conf(msgtype, p, body_len, sender);
                break;
	        case QUERY_LAST_NUMBER_DIALED_CONF: //	= 81,
	            on_query_last_number_dialed_conf(msgtype, p, body_len, sender);
                break;
	        case SNAPSHOT_CALL_CONF			  : //	= 83,
	            on_snapshot_call_conf(msgtype, p, body_len, sender);
                break;
	        case SNAPSHOT_DEVICE_CONF		  : //	= 85,
	            on_snapshot_device_conf(msgtype, p, body_len, sender);
                break;
	        case QUERY_AGENT_WORK_MODE_CONF	  : //	= 88,
	            on_query_agent_work_mode_conf(msgtype, p, body_len, sender);
                break;
	        case SET_AGENT_WORK_MODE_CONF	  : //	= 90,
	            on_set_agent_work_mode_conf(msgtype, p, body_len, sender);
                break;
	        case SEND_DTMF_SIGNAL_CONF		  : //	= 92,
	            on_send_dtmf_signal_conf(msgtype, p, body_len, sender);
                break;
	        case MONITOR_START_CONF			  : //	= 94,
	            on_monitor_start_conf(msgtype, p, body_len, sender);
                break;
	        case MONITOR_STOP_CONF			  : //	= 96,
	            on_monitor_stop_conf(msgtype, p, body_len, sender);
                break;
	        case CHANGE_MONITOR_MASK_CONF	  : //	= 98,
	            on_change_monitor_mask_conf(msgtype, p, body_len, sender);
                break;
	        case SESSION_MONITOR_START_CONF	  : //	= 102,
	            on_session_monitor_start_conf(msgtype, p, body_len, sender);
                break;
	        case SESSION_MONITOR_STOP_CONF	  : //	= 104,
	            on_session_monitor_stop_conf(msgtype, p, body_len, sender);
                break;
	        case USER_MESSAGE_CONF			  : //	= 108,
	            on_user_message_conf(msgtype, p, body_len, sender);
                break;
	        case REGISTER_VARIABLES_CONF	  : //	= 111,
	            on_register_variables_conf(msgtype, p, body_len, sender);
                break;
	        case QUERY_AGENT_STATISTICS_CONF  : //	= 113,
	            on_query_agent_statistics_conf(msgtype, p, body_len, sender);
                break;
	        case QUERY_SKILL_GROUP_STATISTICS_CONF: //	= 115,
	            on_query_skill_group_statistics_conf(msgtype, p, body_len, sender);
                break;
	        case SUPERVISOR_ASSIST_CONF		  : // 	= 119,
	            on_supervisor_assist_conf(msgtype, p, body_len, sender);
                break;
	        case EMERGENCY_CALL_CONF		  : //	= 122,
	            on_emergency_call_conf(msgtype, p, body_len, sender);
                break;
	        case SUPERVISE_CALL_CONF		  : //	= 125,
	            on_supervise_call_conf(msgtype, p, body_len, sender);
                break;
	        case AGENT_TEAM_CONFIG_CONF		  : //	= 127,
	            on_agent_team_config_conf(msgtype, p, body_len, sender);
                break;
	        case SET_APP_DATA_CONF			  : //	= 130,
	            on_set_app_data_conf(msgtype, p, body_len, sender);
                break;
	        case AGENT_DESK_SETTINGS_CONF	  : //	= 132,
	            on_agent_desk_settings_conf(msgtype, p, body_len, sender);
                break;
	        case LIST_AGENT_TEAM_CONF		  : //	= 134,
	            on_list_agent_team_conf(msgtype, p, body_len, sender);
                break;
	        case MONITOR_AGENT_TEAM_START_CONF: //	= 136,
	            on_monitor_agent_team_start_conf(msgtype, p, body_len, sender);
                break;
	        case MONITOR_AGENT_TEAM_STOP_CONF : //	= 138,
	            on_monitor_agent_team_stop_conf(msgtype, p, body_len, sender);
                break;
	        case BAD_CALL_CONF				  : //	= 140,
	            on_bad_call_conf(msgtype, p, body_len, sender);
                break;
	        case SET_DEVICE_ATTRIBUTES_CONF	  : //	= 142,
	            on_set_device_attributes_conf(msgtype, p, body_len, sender);
                break;
	        case REGISTER_SERVICE_CONF		  : //	= 144,
	            on_register_service_conf(msgtype, p, body_len, sender);
                break;
	        case UNREGISTER_SERVICE_CONF	  : //	= 146,
	            on_unregister_service_conf(msgtype, p, body_len, sender);
                break;
	        case START_RECORDING_CONF		  : //	= 148,
	            on_start_recording_conf(msgtype, p, body_len, sender);
                break;
	        case STOP_RECORDING_CONF		  : //	= 150,
	            on_stop_recording_conf(msgtype, p, body_len, sender);
                break;
            // unsolicited msg
	        case FAILURE_EVENT				  : //	= 2,
	            on_failure_event(msgtype, p, body_len, sender);
                break;
	        case CALL_DELIVERED_EVENT		  : //	= 9,
	            on_call_delivered_event(msgtype, p, body_len, sender);
                break;
	        case CALL_ESTABLISHED_EVENT		  : //	= 10,
	            on_call_established_event(msgtype, p, body_len, sender);
                break;
	        case CALL_HELD_EVENT			  : //	= 11,
	            on_call_held_event(msgtype, p, body_len, sender);
                break;
	        case CALL_RETRIEVED_EVENT		  : //	= 12,
	            on_call_retrieved_event(msgtype, p, body_len, sender);
                break;
	        case CALL_CLEARED_EVENT			  : //	= 13,
	            on_call_cleared_event(msgtype, p, body_len, sender);
                break;
	        case CALL_CONNECTION_CLEARED_EVENT: //	= 14,
	            on_call_connection_cleared_event(msgtype, p, body_len, sender);
                break;
	        case CALL_ORIGINATED_EVENT		  : //	= 15,
	            on_call_originated_event(msgtype, p, body_len, sender);
                break;
	        case CALL_FAILED_EVENT			  : //	= 16,
	            on_call_failed_event(msgtype, p, body_len, sender);
                break;
	        case CALL_CONFERENCED_EVENT		  : //	= 17,
	            on_call_conferenced_event(msgtype, p, body_len, sender);
                break;
	        case CALL_TRANSFERRED_EVENT		  : //	= 18,
	            on_call_transferred_event(msgtype, p, body_len, sender);
                break;
	        case CALL_DIVERTED_EVENT		  : //	= 19,
	            on_call_diverted_event(msgtype, p, body_len, sender);
                break;
	        case CALL_SERVICE_INITIATED_EVENT : //	= 20,
	            on_call_service_initiated_event(msgtype, p, body_len, sender);
                break;
	        case CALL_QUEUED_EVENT			  : //	= 21,
	            on_call_queued_event(msgtype, p, body_len, sender);
                break;
	        case CALL_TRANSLATION_ROUTE_EVENT : //	= 22,
	            on_call_translation_route_event(msgtype, p, body_len, sender);
                break;
            case BEGIN_CALL_EVENT			  : //	= 23,
	            on_begin_call_event(msgtype, p, body_len, sender);
                break;
	        case END_CALL_EVENT				  : //	= 24,
	            on_end_call_event(msgtype, p, body_len, sender);
                break;
	        case CALL_DATA_UPDATE_EVENT		  : //	= 25,
	            on_call_data_update_event(msgtype, p, body_len, sender);
                break;
	        case AGENT_STATE_EVENT			  : //	= 30,
	            on_agent_state_event(msgtype, p, body_len, sender);
                break;
	        case SYSTEM_EVENT				  : //	= 31,
	            on_system_event(msgtype, p, body_len, sender);
                break;
	        case CALL_REACHED_NETWORK_EVENT	  : //	= 34,
	            on_call_reached_network_event(msgtype, p, body_len, sender);
                break;
	        case CALL_DEQUEUED_EVENT		  : //	= 86,
	            on_call_dequeued_event(msgtype, p, body_len, sender);
                break;
	        case CLIENT_SESSION_OPENED_EVENT  : //	= 99,
	            on_client_session_opened_event(msgtype, p, body_len, sender);
                break;
	        case CLIENT_SESSION_CLOSED_EVENT  : //	= 100,
	            on_client_session_closed_event(msgtype, p, body_len, sender);
                break;
	        case AGENT_PRE_CALL_EVENT		  : //	= 105,
	            on_agent_pre_call_event(msgtype, p, body_len, sender);
                break;
	        case AGENT_PRE_CALL_ABORT_EVENT	  : //	= 106,
	            on_agent_pre_call_abort_event(msgtype, p, body_len, sender);
                break;
	        case USER_MESSAGE_EVENT			  : //	= 109,
	            on_user_message_event(msgtype, p, body_len, sender);
                break;
	        case RTP_STARTED_EVENT			  : //	= 116,
	            on_rtp_started_event(msgtype, p, body_len, sender);
                break;
	        case RTP_STOPPED_EVENT			  : //	= 117,
	            on_rtp_stopped_event(msgtype, p, body_len, sender);
                break;
	        case SUPERVISOR_ASSIST_EVENT	  : //	= 120,
	            on_supervisor_assist_event(msgtype, p, body_len, sender);
                break;
	        case EMERGENCY_CALL_EVENT		  : //	= 123,
	            on_emergency_call_event(msgtype, p, body_len, sender);
                break;
	        case AGENT_TEAM_CONFIG_EVENT	  : //	= 128,
	            on_agent_team_config_event(msgtype, p, body_len, sender);
                break;	
				
		 */
            default:
                break;
        }


    }
}



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void on_cti_msg_parse(const unsigned char *buf, int len,RecvInfo* Param)
{

        unsigned char msg_buf[MAX_CTILINK_MSG_LENGTH + 512] = { 0 };
        int msg_index = 0;

        if (msg_index < 0 || msg_index > MAX_CTILINK_MSG_LENGTH) {
     //       write_log("error:Invalid recv buffer process logic. reset recv buffer.", LOG_TYPE_CTI);
            msg_index = 0;
        }

		int lenl=len;

        memcpy(msg_buf + msg_index, buf, lenl);
        msg_index += lenl;

        int hdr_len = sizeof(CTI_MHDR);
        while (msg_index >= hdr_len) {
            long body_len = ntohl(((CTI_MHDR *)msg_buf)->MessageLength);
            long msg_type = ntohl(((CTI_MHDR *)msg_buf)->MessageType);
            if ((msg_type < FAILURE_CONF) || (msg_type > LAST_CTI_MSG_TYPE)) {
                //write_hex_msg_log("Recv", msg_buf, msg_index, LOG_TYPE_CTI);
                //write_log("error:Invalid message type:" + VXI_Tools::int_to_str(msg_type), LOG_TYPE_CTI);
                memmove(msg_buf, msg_buf + hdr_len, msg_index - hdr_len);
                msg_index -= hdr_len;
            }
            else if (body_len > (MAX_CTILINK_MSG_LENGTH - hdr_len)) {
                // write_hex_msg_log("Recv", msg_buf, msg_index, LOG_TYPE_CTI);
                //write_log("error:Invalid message length:" + VXI_Tools::int_to_str(hdr_len + body_len), LOG_TYPE_CTI);
                memset(msg_buf, 0, sizeof(msg_buf));
                msg_index = 0;
            }

            else if (body_len > 0) {
                if (msg_index >= (unsigned int)(hdr_len + (unsigned int)body_len)) {

                    if (msg_type == HEARTBEAT_CONF) {
                        //#ifdef WRITE_HEARTBEAT_LOG
                        //write_hex_msg_log("Recv", msg_buf, hdr_len + body_len, LOG_TYPE_CTI);
                        //#endif
                    }
                    else {
                        //write_hex_msg_log("Recv", msg_buf, hdr_len + body_len, LOG_TYPE_CTI);
                    }
                 decode_msg(msg_buf, hdr_len + body_len, Param);


                    memmove(msg_buf, msg_buf + hdr_len + body_len, msg_index - (hdr_len + body_len));
                    msg_index -= hdr_len + body_len;
                }
                else {
                    break;
                }
            }
            else {
                //write_hex_msg_log("Recv", msg_buf, msg_index, LOG_TYPE_CTI);
                //write_log("error:Invalid message body length:" + VXI_Tools::int_to_str(body_len), LOG_TYPE_CTI);
                memset(msg_buf, 0, sizeof(msg_buf));
                msg_index = 0;
            }
        }

};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


void on_cti_msg_recv_func(const char *buf, int len,RecvInfo* Param)
{

    if (buf != NULL && len > 0) {
        bool loop = true;
        unsigned char *p = (unsigned char *)buf;
        while (loop) {
            if (len > MAX_CTILINK_MSG_LENGTH) {
                // testing
                // end testing
                on_cti_msg_parse((unsigned char *)p, MAX_CTILINK_MSG_LENGTH,Param);
                p += MAX_CTILINK_MSG_LENGTH;
                len -= MAX_CTILINK_MSG_LENGTH;
            }
            else {
                // testing
                // end testing
                on_cti_msg_parse((unsigned char *)p, len,Param);
                loop = false;
            }
        }
    }

};



unsigned int decode_uint_msg(unsigned char **pp, int &len)
{
    unsigned int n = -1;
    if (len >= 4) {
        unsigned char *p = *pp;
        n = *p << 24; p++;
        n += *p << 16; p++;
        n += *p << 8; p++;
        n += *p; p++;
        *pp = p;
        len -= 4;
    }
    return n;
}

unsigned short decode_ushort_msg(unsigned char **pp, int &len)
{
    unsigned short n = -1;
    if (len >= 2) {
        unsigned char *p = *pp;
        n = *p << 8; p++;
        n += *p; p++;
        *pp = p;
        len -= 2;
    }
    return n;
}

bool decode_bool_msg(unsigned char **pp, int &len)
{
    return (decode_ushort_msg(pp, len) > 0);
}

char* decode_str_msg(int elemid, unsigned char **pp, int &len)
{
    static char strmsg[512] = { 0 };
    memset(strmsg, 0, sizeof(strmsg));
    if (len > 0) {
        unsigned char *p = *pp;
        int elem = *p;
        if (elem == elemid) {
            p++; len--;
            int elem_len = *p; p++; len--;
            if (len >= elem_len) {
                memcpy(strmsg, p, elem_len);
                p += elem_len;
                len -= elem_len;
            }
        }
        *pp = p;
    }
    return strmsg;
}

unsigned int decode_uint_msg(int elemid, unsigned char **pp, int &len)
{
    unsigned int n = 0;
    if (len > 0) {
        unsigned char *p = *pp;
        int elem = *p;
        if (elem == elemid) {
            p++; len--;
            int elem_len = *p; p++; len--;
            if (len >= elem_len) {
                n = *p << 24; p++;
                n += *p << 16; p++;
                n += *p << 8; p++;
                n += *p; p++;
                len -= 4;
            }
        }
        *pp = p;
    }
    return n;
}

unsigned short decode_ushort_msg(int elemid, unsigned char **pp, int &len)
{
    unsigned short n = 0;
    if (len > 0) {
        unsigned char *p = *pp;
        int elem = *p;
        if (elem == elemid) {
            p++; len--;
            int elem_len = *p; p++; len--;
            if (len >= elem_len) {
                n = *p << 8; p++;
                n += *p; p++;
                len -= 2;
            }
        }
        *pp = p;
    }
    return n;
}

void decode_float_msg(unsigned char **pp, int &len, int msgtype)
{
    if (len > 0) {
        CString trunknumber;
		trunknumber="";
        CString trunkgroup ;
        unsigned char *p = *pp;
        int count = 0;
        while (len > 0 && count < 30) {
            unsigned int elem = *p; p++; len--;
            unsigned int elem_len = *p; p++; len--;
            unsigned char temp[512] = { 0 };
            memcpy(temp, p, elem_len); p += elem_len; len -= elem_len;
            count++;
            switch (elem) {
                case Elem_ClientID:            //        =      1,
                    break;
                case Elem_ClientPassword:      //         =      2,
                case Elem_ClientSignature:     //         =      3,
                    break;
                case Elem_AgentExtension:      //         =      4,
					/*
                    if (evt.items[VXI_EVT_ITEM_DEVICE].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_DEVICE] = (char *)temp;
                        }
                    }
					*/
                    break;
                case Elem_AgentID:               //      =      5,
					/*
                    if (evt.items[VXI_EVT_ITEM_AGENT].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_AGENT] = (char *)temp;
                        }
                    }*/
                    break;
                case Elem_AgentInstrument:     //         =      6,
                    /*
					if (evt.items[VXI_EVT_ITEM_DEVICE].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_DEVICE] = (char *)temp;
                        }
                    }
					*/
                    break;
                case Elem_Text:                //         =      7,
                    /*

					if (evt.items[VXI_EVT_ITEM_TEXT].length() <= 0) {
                        evt.items[VXI_EVT_ITEM_TEXT] = (char *)temp;
                    }
					*/
                    break;
                case Elem_ANI:                //         =      8,
                    /*

					if (evt.items[VXI_EVT_ITEM_CALLING].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_CALLING] = (char *)temp;
                        }
                    }
					*/
                    break;
                case Elem_UserToUserInfo:      //         =      9,
                     /*

                    if (evt.items[VXI_EVT_ITEM_UUI].length() <= 0) {
                        if (temp[0] != '\0') {
                            evt.items[VXI_EVT_ITEM_UUI] = (char *)temp;
                        }
                    }
					*/
                    break;
                case Elem_DNIS:                //         =      10,
					/*
                    if (evt.items[VXI_EVT_ITEM_CALLED].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_CALLED] = (char *)temp;
                        }
                    }
					*/
                    break;
                case Elem_DialedNumber:        //         =      11,
					/*
                    if (evt.items[VXI_EVT_ITEM_CALLED].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_CALLED] = (char *)temp;
                        }
                    }
					*/
                    break;
					/*
                case Elem_CallerEnteredDigits: //         =      12,
                    break;
                case Elem_CallVar1:            //         =      13,     // Var1--Var3: user to user info
                    if (temp[0] != '\0') {
                        evt.items[VXI_EVT_ITEM_UUI] += (char *)temp;
                    }
                    break;
                case Elem_CallVar2:            //         =      14,
                    if (temp[0] != '\0') {
                        evt.items[VXI_EVT_ITEM_UUI] += (char *)temp;
                    }
                    break;
                case Elem_CallVar3:            //         =      15,
                    if (temp[0] != '\0') {
                        evt.items[VXI_EVT_ITEM_UUI] += (char *)temp;
                    }
                    break;
                case Elem_CallVar4:            //         =      16,
                case Elem_CallVar5:            //         =      17,
                case Elem_CallVar6:            //         =      18,
                case Elem_CallVar7:            //         =      19,
                case Elem_CallVar8:            //         =      20,
                case Elem_CallVar9:            //         =      21,
                case Elem_CallVar10:           //         =      22,
                case Elem_CTIClientSignature:  //         =      23,
                case Elem_CTIClientTimeStamp:  //         =      24,
                    break;
                case Elem_ConnectionDeviceID:  //         =      25,
                    if (evt.items[VXI_EVT_ITEM_DEVICE].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_DEVICE] = (char *)temp;
                        }
                    }
                    break;
                case Elem_AlertingDeviceID:    //         =      26,
                    if (evt.items[VXI_EVT_ITEM_ALERT].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_ALERT] = (char *)temp;
                        }
                    }
                    break;
                case Elem_CallingDeviceID:     //         =      27,
                    if (evt.items[VXI_EVT_ITEM_CALLING].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_CALLING] = (char *)temp;
                        }
                    }
                    break;
                case Elem_CalledDeviceID:      //         =      28,
                    if (evt.items[VXI_EVT_ITEM_CALLED].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_CALLED] = (char *)temp;
                        }
                    }
                    if (msgtype == CALL_DIVERTED_EVENT) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_DEST] = (char *)temp;
                        }
                    }
                    break;
                case Elem_LastRedirectDeviceID://         =      29,
                    if (evt.items[VXI_EVT_ITEM_LAST_REDIRECTION].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_LAST_REDIRECTION] = (char *)temp;
                        }
                    }
                    break;
                case Elem_AnsweringDeviceID:   //         =      30,
                    if (evt.items[VXI_EVT_ITEM_ANSWER].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_ANSWER] = (char *)temp;
                        }
                    }
                    break;
                case Elem_HoldingDeviceID:     //         =      31,
                    if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                        evt.items[VXI_EVT_ITEM_DEVICE] = (char *)temp;
                    }
                    break;
                case Elem_RetrievingDeviceID:  //         =      32,
                    if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                        evt.items[VXI_EVT_ITEM_DEVICE] = (char *)temp;
                    }
                    break;
                case Elem_ReleasingDeviceID:   //         =      33,
                    if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                        evt.items[VXI_EVT_ITEM_DEVICE] = (char *)temp;
                    }
                    break;
                case Elem_FailingDeviceID:     //         =      34,
                    //if (evt.items[VXI_EVT_ITEM_FAILING].length() <= 0) {
                    //    evt.items[VXI_EVT_ITEM_FAILING] = (char *)temp;
                    //}
                    if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                        evt.items[VXI_EVT_ITEM_DEVICE] = (char *)temp;
                    }
                    break;
                case Elem_PrimaryDeviceID:     //         =      35,
                    if (evt.items[VXI_EVT_ITEM_DEVICE].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_DEVICE] = (char *)temp;
                        }
                    }
                    break;
                case Elem_SecondaryDeviceID:   //         =      36,
                    //if (evt.items[VXI_EVT_ITEM_DEVICE].length() <= 0) {
                    //    evt.items[VXI_EVT_ITEM_DEVICE] = (char *)temp;
                    //}
                    break;
                case Elem_ControllerDeviceID:  //         =      37,
                    if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                        evt.items[VXI_EVT_ITEM_CONF_CONTROLLER] = (char *)temp;
                    }
                    break;
                case Elem_AddedPartyDeviceID:  //         =      38,
                    if (evt.items[VXI_EVT_ITEM_ADDED_PARTY].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_ADDED_PARTY] = (char *)temp;
                        }
                    }
                    break;
                case Elem_ConnectedPartyCallID: {//         =      39,
                    unsigned char *tempp = temp;
                    unsigned int callid = decode_uint_msg(&tempp, elem_len);
                    if (evt.items[VXI_EVT_ITEM_CALL_LIST].length() <= 0) {
                        evt.items[VXI_EVT_ITEM_CALL_LIST] = VXI_Tools::int_to_str(callid);
                    }
                    else {
                        evt.items[VXI_EVT_ITEM_CALL_LIST] += "," + VXI_Tools::int_to_str(callid);
                    }
                    break;
                }
                case Elem_ConnectedPartyDeviceType://     =      40,
                    break;
                case Elem_ConnectedPartyDeviceID:  //       =      41,
                    if (evt.items[VXI_EVT_ITEM_DEV_LIST].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_DEV_LIST] = (char *)temp;
                        }
                    }
                    else {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_DEV_LIST] += "," + VXI_String((char *)temp);
                        }
                    }
                    break;
                case Elem_TransferringDeviceID:  //       =      42,
                    if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                        evt.items[VXI_EVT_ITEM_TRANSFERRING_DEVICE] = (char *)temp;
                    }
                    break;
                case Elem_TransferredDeviceID:   //       =      43,
                    if (evt.items[VXI_EVT_ITEM_TRANSFERRED_DEVICE].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_TRANSFERRED_DEVICE] = (char *)temp;
                        }
                    }
                    break;
                case Elem_DivertingDeviceID:     //       =      44,
                    if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                        evt.items[VXI_EVT_ITEM_DEVICE] = (char *)temp;
                    }
                    break;
                case Elem_QueueDeviceID:         //       =      45,
                    if (evt.items[VXI_EVT_ITEM_QUEUE].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_QUEUE] = (char *)temp;
                        }
                    }
                    break;
                case Elem_CallWrapupData:        //       =      46,
                case Elem_NewConnectionDeviceID: //       =      47,
                case Elem_TrunkUsedDevID:        //    =      48,
                case Elem_AgentPassword:         //       =      49,
                case Elem_ActiveConnectionDeviceID://     =      50,
                case Elem_FacilityCode:            //  =      51,
                case Elem_OtherConnectionDeviceID: //     =      52,
                case Elem_HeldConnectionDeviceID:  //     =      53,
                    break;
                //case reserved:                   //  =      54,
                //case reserved:                   //  =      55,
                case Elem_CallConnectionCallID: {   //     =      56,
                    unsigned char *tempp = temp;
                    unsigned int callid = decode_uint_msg(&tempp, elem_len);
                    if (evt.items[VXI_EVT_ITEM_CALL].length() <= 0) {
                        evt.items[VXI_EVT_ITEM_CALL] = VXI_Tools::int_to_str(callid);
                    }
                    if (evt.items[VXI_EVT_ITEM_CALL_LIST].length() <= 0) {
                        evt.items[VXI_EVT_ITEM_CALL_LIST] = VXI_Tools::int_to_str(callid);
                    }
                    else {
                        evt.items[VXI_EVT_ITEM_CALL_LIST] += "," + VXI_Tools::int_to_str(callid);
                    }
                    break;
                }
                case Elem_CallConnectionDeviceType://     =      57,
                    break;
                case Elem_CallConnectionDeviceID:  //     =      58,
                    if (evt.items[VXI_EVT_ITEM_DEV_LIST].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_DEV_LIST] = (char *)temp;
                        }
                    }
                    else {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_DEV_LIST] += "," + VXI_String((char *)temp);
                        }
                    }
                    break;
                case Elem_CallDeviceType:          //     =      59,
                    break;
                case Elem_CallDeviceID:            //     =      60,
                    if (evt.items[VXI_EVT_ITEM_DEV_LIST].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_DEV_LIST] = (char *)temp;
                        }
                    }
                    else {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_DEV_LIST] += "," + VXI_String((char *)temp);
                        }
                    }
                    break;
                case Elem_CallDeviceConnectionState://    =      61,
                    break;
                case Elem_CSQID:                    //    =      62,
                case Elem_SkillGroupID:             // =      63,
                    if (evt.items[VXI_EVT_ITEM_SKILL].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_SKILL] = (char *)temp;
                        }
                    }
                    break;
                case Elem_SkillGroupPriority:       // =      64,
                case Elem_CSQState:                 //    =      65,
                case Elem_ObjectName:               // =      66,
                case Elem_DTMFString:               //    =      67,
                case Elem_PositionID:               // =      68,
                case Elem_SupervisorID:             // =      69,
                case Elem_LineHandle:               // =      70,
                case Elem_LineType:                 // =      71,
                case Elem_RoutedCallKeyDay:         // =      72,
                case Elem_RoutedCallKeyCallID:      // =      73,
                //case reserved:                    // =      74,
                case Elem_CallState:                // =      75,
                case Elem_MonitoredDevID:           // =      76,
                case Elem_AuthorizationCode:        // =      77,
                case Elem_AccountCode:              //    =      78,
                case Elem_OriginatingDevID:                    // =      79,
                case Elem_OriginatingLineID:                    // =      80,
                case Elem_ClientAddress:            //    =      81,
                case Elem_NamedVariable:            //    =      82,
                case Elem_NamedArray:               //    =      83,
                case Elem_CallControlTable:         // =      84,
                case Elem_SupervisorInstrument:     //    =      85,
                case Elem_ATCAgentID:               // =      86,
                case Elem_AgentFlags:               //    =      87,
                case Elem_ATCAgentState:            // =      88,
                case Elem_ATCAgentDuration:         // =      89,
                case Elem_Elem_AgentConnectionDeviceID://      =      90,
                case Elem_SupervisorConnectionDeviceID:// =      91,
                case Elem_ListTeamID:                  //=      92,
                case Elem_DefaultDevicePortAddress:    // =      93,
                case Elem_ServiceName:                 // =      94,
                case Elem_CustomerPhoneNumber:      //    =      95,
                case Elem_CustomerAccountNumber:    //    =      96,
                case Elem_AppPath:                  // =      97,
                //case reserved:                    // =      98,
                //case reserved:                    // =      99,
                //case reserved:                    //     =      100,
                //case reserved:                    //     =      101,
                //case reserved:                    //     =      102,
                //case reserved:                    //     =      103,
                //case reserved:                    //     =      104,
                //case reserved:                    //     =      105,
                //case reserved:                    //     =      106,
                //case reserved:                    //     =      107,
                //case reserved:                    //     =      108,
                //case reserved:                    //     =      109,
                case Elem_RoutedCallKeySequenceNum: //     =      110,
                //case reserved:                    //     =      111,
                //case reserved:                    //     =      112,
                //case reserved:                    //     =      113,
                //case reserved:                    //     =      114,
                //case reserved:                    //     =      115,
                //case reserved:                    //     =      116,
                //case reserved:                    //     =      117,
                //case reserved:                    //     =      118,
                //case reserved:                    //     =      119,
                //case reserved:                    //     =      120,
                case Elem_TrunkNumber:              //     =      121,
                    trunknumber = (char *)temp;
                    break;
                case Elem_TrunkGroup:               //     =      122,
                    trunkgroup = (char *)temp;
                    break;
                case Elem_NextAgentState:           //        =      123,
                case Elem_DequeueType:              //     =      124,
                case Elem_SendingAddress:           //     =      125,
                case Elem_SendingPort:              //        =      126,
                //case reserved:                    //     =      127,
                //case reserved:                    //     =      128,
                case Elem_MaxQueued:                //        =      129,
                case Elem_QueueID:                  //     =      130,
                    if (evt.items[VXI_EVT_ITEM_QUEUE].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_QUEUE] = (char *)temp;
                        }
                    }
                    break;
                case Elem_CustomerID:               //     =      131,
                    break;
                case Elem_ServiceSkillTargetID:     //        =      132,
                    if (evt.items[VXI_EVT_ITEM_QUEUE].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_QUEUE] = (char *)temp;
                        }
                    }
                    break;
                case Elem_PeripheralName:           //        =      133,
                case Elem_Description:              //        =      134,
                case Elem_ServiceMemberID:                    //     =      135,
                case Elem_ServiceMemberPriority:                    //     =      136,
                case Elem_FirstName:                //        =      137,
                case Elem_LastName:                 //        =      138,
                    break;
                case Elem_SkillGroup:               //     =      139,
                    if (evt.items[VXI_EVT_ITEM_QUEUE].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_QUEUE] = (char *)temp;
                        }
                    }
                    break;
                //case reserved:                    //     =      140,
                case Elem_AgentSkillTargetID:       //     =      141,
                    if (evt.items[VXI_EVT_ITEM_QUEUE].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_QUEUE] = (char *)temp;
                        }
                    }
                    break;
                case Elem_Service:                    //     =      142,
                //case reserved:                    //     =      143,
                //case reserved:                    //     =      144,
                //case reserved:                    //     =      145,
                //case reserved:                    //     =      146,
                //case reserved:                    //     =      147,
                //case reserved:                    //     =      148,
                //case reserved:                    //     =      149,
                    break;
                case Elem_Duration:                 //        =      150,
                    if (evt.items[VXI_EVT_ITEM_DURATION_TIME].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_DURATION_TIME] = (char *)temp;
                        }
                    }
                    break;
                //case reserved:                    //     =      151,
                //case reserved:                    //     =      152,
                //case reserved:                    //     =      153,
                //case reserved:                    //     =      154,
                //case reserved:                    //     =      155,
                //case reserved:                    //     =      156,
                //case reserved:                    //     =      157,
                //case reserved:                    //     =      158,
                //case reserved:                    //     =      159,
                //case reserved:                    //     =      160,
                //case reserved:                    //     =      161,
                //case reserved:                    //     =      162,
                //case reserved:                    //     =      163,
                //case reserved:                    //     =      164,
                //case reserved:                    //     =      165,
                //case reserved:                    //     =      166,
                //case reserved:                    //     =      167,
                //case reserved:                    //     =      168,
                //case reserved:                    //     =      169,
                //case reserved:                    //     =      170,
                //case reserved:                    //     =      171,
                //case reserved:                    //     =      172,
                case Elem_Extension:                //        =      173,
				
                    if (evt.items[VXI_EVT_ITEM_DEVICE].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_DEVICE] = (char *)temp;
                        }
                    }
			
                    break;
                case Elem_ServiceLevelThreshold:    //     =      174,
                case Elem_ServiceLevelType:         //     =      175,
                case Elem_ConfigParam:              //     =      176,
                case Elem_ApplicationConfigKey:     //        =      177,
                case Elem_CSQConfigKey:             //        =      178,
                case Elem_AgentConfigKey:           //        =      179,
                case Elem_DeviceConfigKey:          //        =      180,
                //case reserved:                    //     =      181,
                //case reserved:                    //     =      182,
                case Elem_RecordType:               //        =      183,
                case Elem_PeripheralNumber:         //          =      184,
                case Elem_AutoWork:                 //        =      185,
                //case reserved:                    //     =      186,
                //case reserved:                    //     =      187,
                //case reserved:                    //     =      188,
                case Elem_AgentType:                //        =      189,
                case Elem_LoginID:                  //        =      190,
                case Elem_NumCSQs:                  //        =      191,
                //case reserved:                    //     =      192,
                case Elem_DeviceField1:             //        =      193,
                    break;
                case Elem_AgentID_Long:                  //        =      194,
			
                    if (evt.items[VXI_EVT_ITEM_AGENT].length() <= 0) {
                        if (temp[0] != '\0' && temp[0] != '-' && temp[0] != 'U' && temp[0] != 'u') {
                            evt.items[VXI_EVT_ITEM_AGENT] = (char *)temp;
                        }
                    }
			
                    break;
                case Elem_DeviceType:               //        =      195,
                //case reserved:                    //     =      196,
                //case reserved:                    //     =      197,
                //case reserved:                    //     =      198,
                //case reserved:                    //     =      199,
                //case reserved:                    //     =      200,
                //case reserved:                    //     =      201,
                case Elem_SecondaryConnectionCallID://        =      202,
                //case reserved:                    //     =      203,
                case Elem_TeamName:                 //        =      204,
                case Elem_MemberType:               //        =      205,
                case Elem_EventDeviceID:            //        =      206,
                //case reserved:                    //     =      207,
                //case reserved:                    //     =      208,
                //case reserved:                    //     =      209,
                //case reserved:                    //     =      210,
                //case reserved:                    //     =      211,
                //case reserved:                    //     =      212,
                //case reserved:                    //     =      213,
                //case reserved:                    //     =      214,
                //case reserved:                    //     =      215,
                //case reserved:                    //     =      216
					
					*/
                default:
                    break;
            }
        }
        *pp = p;


        if (trunkgroup.GetLength() > 0 && trunknumber.GetLength() > 0) {
           // evt.items[VXI_EVT_ITEM_TRUNK] = trunkgroup + "," + trunknumber;
        }
    }
}




void on_open_conf(unsigned char *ps,RecvInfo* Param)
{
    RecvInfo* PP=(RecvInfo*)Param;
	RecvSendInfo*Ps=PP->SockInfo;

    unsigned char msgbuf[512] = { 0 };
    unsigned char *p = msgbuf;
    encode_uint_msg(&p, 0, 0, true);
    encode_uint_msg(&p, 0, OPEN_CONF, true);


	unsigned int invokeid=ntohl((unsigned int)ps);
	encode_uint_msg(&p, 0, invokeid, true);
	encode_uint_msg(&p, 0, 16, true);       //ServiceGranted 0x10


	encode_uint_msg(&p, 0, 0, true);        //Researved 
	encode_uint_msg(&p, 0, 0, true);        //Researved 
	encode_uint_msg(&p, 0, 0, true);        //Researved 

	encode_bool_msg(&p, 0, 1, true);        // UCCX online
	encode_ushort_msg(&p, 0, 0, true);      //Reserved
	encode_ushort_msg(&p, 0, 0, true);      //Reserved

	int msg_len = encode_msg(msgbuf, p);





	send(Ps->conSock,(char*)msgbuf,msg_len,0);
	Sleep(20);



}



void on_heartbeat_conf(unsigned char *ps,RecvInfo* Param)
{
    RecvInfo* PP=(RecvInfo*)Param;
	RecvSendInfo*Ps=PP->SockInfo;

	unsigned char msgbuf[512] = { 0 };
    unsigned char *p = msgbuf;

	encode_uint_msg(&p, 0, 0, true);
    encode_uint_msg(&p, 0, HEARTBEAT_REQ, true);

	unsigned int invokeid=ntohl((unsigned int)ps);
	encode_uint_msg(&p, 0, invokeid, true);
	int msg_len = encode_msg(msgbuf, p);
	send(Ps->conSock,(char*)msgbuf,msg_len,0);
	Sleep(20);

}


void on_close_conf(unsigned char *ps,RecvInfo* Param)
{
    RecvInfo* PP=(RecvInfo*)Param;
	RecvSendInfo*Ps=PP->SockInfo;

	unsigned char msgbuf[512] = { 0 };
    unsigned char *p = msgbuf;

	encode_uint_msg(&p, 0, 0, true);
    encode_uint_msg(&p, 0, CLOSE_REQ, true);

	unsigned int invokeid=ntohl((unsigned int)ps);
	encode_uint_msg(&p, 0, invokeid, true);
	int msg_len = encode_msg(msgbuf, p);
	send(Ps->conSock,(char*)msgbuf,msg_len,0);
	Sleep(20);

}

void on_query_device_info_conf(unsigned char *ps,RecvInfo* Param)
{
	RecvInfo* PP=(RecvInfo*)Param;
	RecvSendInfo*Ps=PP->SockInfo;

	unsigned char msgbuf[512] = { 0 };
    unsigned char *p = msgbuf;

	encode_uint_msg(&p, 0, 0, true);
    encode_uint_msg(&p, 0, QUERY_DEVICE_INFO_CONF, true);

	unsigned int invokeid=ntohl((unsigned int)ps);
	char aa[20];
	sprintf(aa,"%d",invokeid);
   // MessageBoxA(NULL,aa,"Alert",NULL);

	encode_uint_msg(&p, 0, invokeid, true);          //InvokeID
    encode_ushort_msg(&p, 0, 21, true);              //21, reserved 
	encode_ushort_msg(&p, 0, -1, true);              //-1, reserved
	encode_ushort_msg(&p, 0, -1, true);              //-1, reserved
	encode_ushort_msg(&p, 0, 0, true);               //0, reserved
	encode_ushort_msg(&p, 0, 0, true);               //0, reserved
	encode_ushort_msg(&p, 0, 200, true);               //5, Maximun active call
	encode_ushort_msg(&p, 0,0xffff, true);           //Unknow, Maximun participants number
	encode_uint_msg(&p, 0, 0x1ff, true);             //MakeCallSetup
    encode_uint_msg(&p, 0, 0, true);                 //0, reserved.
	encode_uint_msg(&p, 0, 0, true);                 //0, reserved.
	encode_uint_msg(&p, 0, 0, true);                 //0, reserved.
	encode_uint_msg(&p, 0, 0, true);                 //0, reserved.


	// floating part
	USHORT pa=0xffff;
	char temp[3];

	memcpy(temp,(char*)&pa,2);
	temp[2]='\0';
    encode_fushort_msg(&p, 70, temp, false);             //0xffff, USHORT, reserved

	pa=0x0300;
	memcpy(temp,(char*)&pa,2);
	temp[2]='\0';
	encode_fushort_msg(&p, 71, temp, false);             //3, USHORT, reserved

	int msg_len = encode_msg(msgbuf, p);
	
	send(Ps->conSock,(char*)msgbuf,msg_len,0);
	Sleep(20);

}


void on_query_agent_state_conf(unsigned char *ps,RecvInfo* Param)
{
    RecvInfo* PP=(RecvInfo*)Param;
    RecvSendInfo*Ps=PP->SockInfo;

	unsigned char msgbuf[512] = { 0 };
    unsigned char *p = msgbuf;

    static int i=0;
	static bool in=false;

	if(in)
	{
		in=false;
	}
	else
	{

		in=true;
	}

	int inNuma, outNuma;
	char temp[10];

	if(in)
	{
		if (i<iThreadNum)
		{
			i++;
		}
		else
		{
			i=0;
		}
		outNuma=atoi(outNum)+i;
		sprintf(temp,"%d",outNuma);
	}
	else
	{
        inNuma=atoi(outNum)+i;
		sprintf(temp,"%d",outNuma);
	}



	encode_uint_msg(&p, 0, 0, true);
    encode_uint_msg(&p, 0, QUERY_AGENT_STATE_CONF, true);

	unsigned int invokeid=ntohl((unsigned int)ps);
	char aa[20];
	sprintf(aa,"%d",invokeid);
   // MessageBoxA(NULL,aa,"Alert",NULL);

	encode_uint_msg(&p, 0, invokeid, true);          //InvokeID

	switch (Slogin) 
	{
	case 0: encode_ushort_msg(&p, 0, 0, true); break;  //Login
	case 1: encode_ushort_msg(&p, 0, 1, true); break;  //Log out
	case 2: encode_ushort_msg(&p, 0, 2, true); break;  //Not ready
	case 3: encode_ushort_msg(&p, 0, 3, true); break;  //Ready
	case 4: encode_ushort_msg(&p, 0, 4, true); break;  //Talking
	case 5: encode_ushort_msg(&p, 0, 5, true); break;  //Working
	case 8: encode_ushort_msg(&p, 0, 8, true); break;  //Researved status

    default: break;

   
	}
//	encode_ushort_msg(&p, 0, 2, true);        //1, Agent state Login
	encode_ushort_msg(&p, 0, 1, true);        //1, CQSID
	encode_uint_msg(&p, 0, 1, true);          //Reserved
	encode_uint_msg(&p, 0, 0, true);          //Reserved
	encode_ushort_msg(&p, 0, 0, true);        //0, Reserved
	encode_uint_msg(&p, 0, 0, true);          //Reserved
	encode_uint_msg(&p, 0, 0, true);          //Reserved
	encode_uint_msg(&p, 0, 1, true);          //Reserved

	//Floating part

	encode_str_msg(&p, Elem_AgentID_Long, temp, false);

	encode_str_msg(&p, Elem_AgentExtension, temp, false);


   	USHORT pa=0;                       
	char temp1[3];

	memcpy(temp1,(char*)&pa,2);
	temp1[2]='\0';
	encode_fushort_msg(&p, 65, temp1, false);             //0,CSQState 

	encode_ushort_msg(&p, 0, 0x3E04, true);          // Elem_CSQID=62, Len=4
	encode_uint_msg(&p, 0, 1, true);          //CSQID=1

	int msg_len = encode_msg(msgbuf, p);
	
	send(Ps->conSock,(char*)msgbuf,msg_len,0);
	Sleep(20);


     





}

void on_agent_state_event(RecvInfo* Param)
{

   	RecvInfo* PP=(RecvInfo*)Param;
	RecvSendInfo*Ps=PP->SockInfo;

	unsigned char msgbuf[512] = { 0 };
    unsigned char *p = msgbuf;

	   
	static int i=0;
	static bool in=false;

	if(in)
	{
		in=false;
	}
	else
	{

		in=true;
	}

	int inNuma, outNuma;
	char temp[10];

	//if(in)
	//{
		if (i<iThreadNum)
		{
			i++;
		}
		else
		{
			i=0;
		}
		outNuma=atoi(outNum)+i;
		sprintf(temp,"%d",outNuma);
	//}
	//else
	//{
    //    outNuma=atoi(outNum)+i+1;
	//	sprintf(temp,"%d",outNuma);
	//}

	encode_uint_msg(&p, 0, 0, true);
    encode_uint_msg(&p, 0, AGENT_STATE_EVENT, true);

	encode_uint_msg(&p, 0, 0, true);      //Researved 0;
	encode_uint_msg(&p, 0, 1, true);      //Researved 1;
	encode_uint_msg(&p, 0, 0, true);      //Researved 0;
	encode_ushort_msg(&p, 0, 21, true);   //Researved 21;
    
	switch (Slogin) 
	{
	case 0: encode_ushort_msg(&p, 0, 0, true); break;  //Login
	case 1: encode_ushort_msg(&p, 0, 1, true); break;  //Log out
	case 2: encode_ushort_msg(&p, 0, 2, true); break;  //Not ready
	case 3: encode_ushort_msg(&p, 0, 3, true); break;  //Ready
	case 4: encode_ushort_msg(&p, 0, 4, true); break;  //Talking
	case 5: encode_ushort_msg(&p, 0, 5, true); break;  //Working
	case 8: encode_ushort_msg(&p, 0, 8, true); break;  //Researved status

    default: break;
 
	}



	encode_uint_msg(&p, 0, 0, true);      //State Duration 0;
	encode_uint_msg(&p, 0, 0xffffffff, true);      //CSQID,0xffffffff
	encode_uint_msg(&p, 0, 0xffffffff, true);      //researved,0xffffffff
	encode_ushort_msg(&p, 0, 0, true);            //       Researved 0;
	encode_ushort_msg(&p, 0, Slogin, true);            //      Set status;
	encode_ushort_msg(&p, 0, 0x7ff8, true);          //Event reason code
	encode_uint_msg(&p, 0, 1, true);               //Researved 1;
	encode_uint_msg(&p, 0, 0, true);               //Researved 0;
    encode_ushort_msg(&p, 0, 0, true);             //Researved 0;
	encode_uint_msg(&p, 0, 0, true);               //Researved 0;
	encode_uint_msg(&p, 0, 0, true);               //Researved 0;
	encode_uint_msg(&p, 0, 1, true);               //Researved 1;
	encode_ushort_msg(&p, 0, 0, true);             //NumCSQs;


	//Floating part
	encode_str_msg(&p, Elem_AgentExtension, temp, false); // Agent Extension.
	encode_str_msg(&p, Elem_AgentID_Long, temp, false); // Agent Extension.
	encode_str_msg(&p, Elem_AgentID, temp, false); // Agent Extension.


	int msg_len = encode_msg(msgbuf, p);
	
	send(Ps->conSock,(char*)msgbuf,msg_len,0);
	Sleep(20);




}


void on_set_agent_state_conf(unsigned char *ps,RecvInfo* Param)
{

   	RecvInfo* PP=(RecvInfo*)Param;
	RecvSendInfo*Ps=PP->SockInfo;

	on_agent_state_event(Param);




	unsigned char msgbuf[512] = { 0 };
    unsigned char *p = msgbuf;

	encode_uint_msg(&p, 0, 0, true);
    encode_uint_msg(&p, 0, QUERY_DEVICE_INFO_CONF, true);

	unsigned int invokeid=ntohl((unsigned int)ps);
	char aa[20];
	sprintf(aa,"%d",invokeid);
   // MessageBoxA(NULL,aa,"Alert",NULL);

	encode_uint_msg(&p, 0, invokeid, true);          //InvokeID

	int msg_len = encode_msg(msgbuf, p);
	
	send(Ps->conSock,(char*)msgbuf,msg_len,0);


}



void on_begin_call_event(RecvSendInfo Param,char* inNum,char* outNum,int callid)
{
   
	unsigned char msgbuf[512] = { 0 };
    unsigned char *p = msgbuf;
	encode_uint_msg(&p, 0, 0, true);
	encode_uint_msg(&p, 0, BEGIN_CALL_EVENT, true);

	encode_uint_msg(&p, 0, 0, true);           //reserved
	encode_uint_msg(&p, 0, 1, true);           //reserved
	encode_ushort_msg(&p, 0, 21, true);        //21, reserved 
	
	encode_ushort_msg(&p, 0, 0, true);              //0, NumCTIClients
	encode_ushort_msg(&p, 0, 0, true);              //0, NumNamedVariables
    encode_ushort_msg(&p, 0, 0, true);              //0, NumNamedArrays
	encode_ushort_msg(&p, 0, 9, true);              //1, CallType
    encode_ushort_msg(&p, 0, 0, true);              //1, ConnectionDeviceType
	encode_uint_msg(&p, 0, callid, true);          // CallID
	encode_ushort_msg(&p, 0, 0, true);              //0, CalledPartyDisposition


	// floating part

    encode_str_msg(&p, Elem_ConnectionDeviceID, inNum, false);
	encode_str_msg(&p, Elem_ANI, inNum, false);              //主叫.
	encode_str_msg(&p, Elem_DialedNumber, outNum, false);    //被叫

	int msg_len = encode_msg(msgbuf, p);
	
	send(Param.conSock,(char*)msgbuf,msg_len,0);
	Sleep(20);


}




void on_call_delivered_event(RecvSendInfo Param,char* inNum,char* outNum,int callid)
{
	unsigned char msgbuf[512] = { 0 };
    unsigned char *p = msgbuf;
	encode_uint_msg(&p, 0, 0, true);
	encode_uint_msg(&p, 0, CALL_DELIVERED_EVENT, true);

	encode_uint_msg(&p, 0, 0, true);           //reserved
	encode_uint_msg(&p, 0, 1, true);           //reserved
	encode_ushort_msg(&p, 0, 21, true);        //21, reserved 

	encode_ushort_msg(&p, 0, 0, true);         //1, ConnectionDeviceType
	encode_uint_msg(&p, 0, callid, true);    // CallID

	encode_ushort_msg(&p, 0, 0xffff, true);   //0xffff, reserved 
	encode_ushort_msg(&p, 0, 3, true);        //3, reserved 

	encode_uint_msg(&p, 0, 123456, true);           //Application ID
	encode_uint_msg(&p, 0, 0xffffffff, true);       //reserved
	encode_uint_msg(&p, 0, 0, true);           //The Contact Service Queue ID of the call, skill
	encode_uint_msg(&p, 0, 0xffffffff, true);       //reserved
	encode_ushort_msg(&p, 0, 0, true);              //0, reserved 
	encode_ushort_msg(&p, 0, 0xffff, true);         //AlertingDeviceType, not provide
	encode_ushort_msg(&p, 0, 2, true);              // CallingDeviceType, 0_ip phone
	encode_ushort_msg(&p, 0, 0, true);              // CalledDeviceType, 76_agent device
	encode_ushort_msg(&p, 0, 0xffff, true);              // LastRedirectDeviceType, not provide

	encode_ushort_msg(&p, 0, 0, true);              // LocalConnectionState, no relationship
	encode_ushort_msg(&p, 0, 22, true);              // EventCause, new call
	encode_ushort_msg(&p, 0, 0, true);              //0, NumNamedVariables
    encode_ushort_msg(&p, 0, 0, true);              //0, NumNamedArrays


	// floating part
	encode_str_msg(&p, Elem_ConnectionDeviceID, inNum, false);
	encode_str_msg(&p, Elem_AlertingDeviceID, outNum, false); //被叫
	encode_str_msg(&p, Elem_CalledDeviceID, outNum, false);   //被叫
	encode_str_msg(&p, Elem_ANI, inNum, false);              // 主叫
    encode_str_msg(&p, Elem_DNIS, outNum, false);             //被叫
	encode_str_msg(&p, Elem_DialedNumber, outNum, false);     //被叫

	int msg_len = encode_msg(msgbuf, p);
	
	send(Param.conSock,(char*)msgbuf,msg_len,0);
	Sleep(20);

}



void on_call_established_event(RecvSendInfo Param,char* inNum,char* outNum,int callid)
{

	unsigned char msgbuf[512] = { 0 };
    unsigned char *p = msgbuf;
	encode_uint_msg(&p, 0, 0, true);
	encode_uint_msg(&p, 0, CALL_ESTABLISHED_EVENT, true);

	encode_uint_msg(&p, 0, 0, true);           //reserved
	encode_uint_msg(&p, 0, 1, true);           //reserved
	encode_ushort_msg(&p, 0, 21, true);        //21, reserved 

	encode_ushort_msg(&p, 0, 0, true);         //1, ConnectionDeviceType
	encode_uint_msg(&p, 0, callid, true);    // CallID
		
	encode_ushort_msg(&p, 0, 0xffff, true);   //0xffff, reserved 
	encode_ushort_msg(&p, 0, 3, true);        //3, reserved 

	encode_uint_msg(&p, 0, 123456, true);           //Application ID

	encode_uint_msg(&p, 0, 0xffffffff, true);      //reserved
	encode_uint_msg(&p, 0, 0, true);           //The Contact Service Queue ID of the call, skill
	//encode_uint_msg(&p, 0, 4775, true);           //The Contact Service Queue ID of the call, skill
	encode_uint_msg(&p, 0, 0xffffffff, true);       //reserved
	encode_ushort_msg(&p, 0, 0, true);              //0, reserved 

	encode_ushort_msg(&p, 0, 0, true);               //Answer DeviceType, 0_ip phone
	encode_ushort_msg(&p, 0, 2, true);              // CallingDeviceType, 2_soft phone
	encode_ushort_msg(&p, 0, 0, true);              // CalledDeviceType, 76_agent device
	encode_ushort_msg(&p, 0, 0xffff, true);              // LastRedirectDeviceType, not provide

	encode_ushort_msg(&p, 0, 0, true);              // LocalConnectionState, no relationship
	encode_ushort_msg(&p, 0, 22, true);              // EventCause, new call

	// floating part
	encode_str_msg(&p, Elem_ConnectionDeviceID, inNum, false);
	encode_str_msg(&p, Elem_AnsweringDeviceID, outNum, false);      //被叫
	encode_str_msg(&p, Elem_CallingDeviceID, inNum, false);        //主叫
	encode_str_msg(&p, Elem_CalledDeviceID, outNum, false);         //被叫


	int msg_len = encode_msg(msgbuf, p);
	
	send(Param.conSock,(char*)msgbuf,msg_len,0);
	Sleep(20);



}
void on_conn_clear_event(RecvSendInfo Param,char* inNum,char* outNum,int callid)
{
 	unsigned char msgbuf[512] = { 0 };
    unsigned char *p = msgbuf;
	encode_uint_msg(&p, 0, 0, true);
	encode_uint_msg(&p, 0, CALL_CONNECTION_CLEARED_EVENT, true);

	encode_uint_msg(&p, 0, 0, true);           //reserved
	encode_uint_msg(&p, 0, 1, true);           //reserved
	encode_ushort_msg(&p, 0, 21, true);        //21, reserved 

	encode_ushort_msg(&p, 0, 0, true);         //1, ConnectionDeviceType
	encode_uint_msg(&p, 0, callid, true);    // CallID

	encode_ushort_msg(&p, 0, 0, true);         //1, ReleaseDeviceType
	encode_ushort_msg(&p, 0, 0, true);         //0, LocalConnectionState
	encode_ushort_msg(&p, 0, 1, true);         //0, reserved

	// floating part
	encode_str_msg(&p, Elem_ConnectionDeviceID, outNum, false);
	encode_str_msg(&p, Elem_ReleasingDeviceID, outNum, false);
	int msg_len = encode_msg(msgbuf, p);
	
	send(Param.conSock,(char*)msgbuf,msg_len,0);
	Sleep(20);

}

void on_end_call_event(RecvSendInfo Param,char* inNum,char* outNum,int callid)
{

	unsigned char msgbuf[512] = { 0 };
    unsigned char *p = msgbuf;
	encode_uint_msg(&p, 0, 0, true);
	encode_uint_msg(&p, 0, END_CALL_EVENT, true);

	encode_uint_msg(&p, 0, 0, true);           //reserved
	encode_uint_msg(&p, 0, 1, true);           //reserved
	encode_ushort_msg(&p, 0, 21, true);        //21, reserved 

	encode_ushort_msg(&p, 0, 0, true);         //1, ConnectionDeviceType
	encode_uint_msg(&p, 0, callid, true);    // CallID

	// floating part
	encode_str_msg(&p, Elem_ConnectionDeviceID, outNum, false);
	int msg_len = encode_msg(msgbuf, p);
	
	send(Param.conSock,(char*)msgbuf,msg_len,0);
	Sleep(20);

}




void on_rtp_started_event(RecvSendInfo Param,char* inNum,char* outNum,int callid)
{
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//int send_invite_message(const char* inNum,const char* outNum,int callid,const char*tag, const char* branch,int point)
int send_invite_message(const char* inNum,const char* outNum,int callid,const char*tag,const char*nfend, const char* branch,int point)
{
    char buffer[1500];
	sprintf(buffer,"INVITE sip:1637@%s:5060 SIP\/2.0\r\n", SockVrs->ipadd);

    time_t t = time(0);  
	char tmp[64];
	strftime(tmp, sizeof(tmp), "Data:%a, %d %b %Y %X GMT",localtime(&t));
    

	sprintf(buffer,"%s%s\r\n",buffer,tmp);
	sprintf(buffer,"%sCall-Info: <sip:%s:5060>;method=\"NOTIFY;Event=telephone-event;Duration=500\"\r\n",buffer,SerIP);
	sprintf(buffer,"%sAllow: INVITE, OPTIONS, INFO, BYE, CANCEL, ACK, PRACK, UPDATE, REFER, SUBSCRIBE, NOTIFY\r\n",buffer);
	//sprintf(buffer,"%sFrom: \"%s\" <sip:%s@%s;x-nearend;x-refci=%d;x-nearenddevice=SEP001558E6%d>;tag=%s\n",buffer,outNum,outNum,SerIP,callid,outNum,tag);
	sprintf(buffer,"%sFrom: \"%s\" <sip:%s@%s;%s;x-refci=%d;x-nearenddevice=SEP001558E6%d>;tag=%s\r\n",buffer,outNum,outNum,SerIP,nfend,callid,outNum,tag);
	sprintf(buffer,"%sAllow-Events: presence, kpml\r\n",buffer);
	sprintf(buffer,"%sSupported: timer,resource-priority,replaces\r\n",buffer);
	sprintf(buffer,"%sMin-SE:  1800\r\n",buffer);
	sprintf(buffer,"%sRemote-Party-ID: <sip:%s@%s>;party=calling;screen=no;privacy=off\r\n",buffer,outNum,SerIP);
	sprintf(buffer,"%sContent-Length: 0\r\n",buffer);
	sprintf(buffer,"%sUser-Agent: Cisco-CUCM7.0\r\n",buffer);
    sprintf(buffer,"%sTo: <sip:1637@%s>\r\n",buffer,SockVrs->ipadd);
	sprintf(buffer,"%sContact: <sip:%s@%s:5060;transport=tcp>;isfocus\r\n",buffer,outNum,SerIP);
	sprintf(buffer,"%sExpires: 180\r\n",buffer);
	sprintf(buffer,"%sCall-ID: c2738200-ed4187fd-22a8d-%x@%s\r\n",buffer,callid,SerIP);
	sprintf(buffer,"%sVia: SIP/2.0/TCP %s:5060;branch=%s\r\n",buffer,SerIP,branch);
    sprintf(buffer,"%sCSeq: 101 INVITE\r\n",buffer);
	sprintf(buffer,"%sP-Preferred-Identity: <sip:%s@%s>\r\n",buffer,outNum,SerIP);
	sprintf(buffer,"%sSession-Expires:  1800\r\n",buffer);
	sprintf(buffer,"%sMax-Forwards: 70\r\n\r\n",buffer);

   
	int flag=0;
	int c=1;
	while (((flag=send(SockVrs->SockClient[point],(char*)buffer,strlen(buffer)+1,0))<0)||(flag==0))
	{
		if (c==15)
		{   
			if((logfp=fopen("log.txt","at+"))==NULL)
			{
				MessageBoxA(NULL, "Cannot open log file.\n","Alert",1);
			}
			else
		    { 
			 strftime(tmp, sizeof(tmp), "Time: %a, %d %b %Y %X GMT",localtime(&t));
			 fprintf(logfp,"%s, Cannot send the invitation to VRS:%d, called:%s, Callid:%d \n",tmp, point, outNum,callid);
			 
			}
			fclose(logfp);
			return 0;
		}

	  c++;
	  Sleep(2000);
	}
 //   strncpy(SockVrs->msgarry[point],buffer,1500);


	//MessageBoxA(NULL, buffer, "alert",1);
	OutputDebugStringA(buffer);

	return 1;
 




}

void send_ack_message(const char* inNum,const char* outNum,int callid,const char* tag,const char* branch, int point)
{
    
    char sdpbuffer[300];
	sprintf(sdpbuffer,"v=0\r\n");
	sprintf(sdpbuffer,"%so=CiscoSystemsCCM-SIP 2000 1 IN IP4 %s\r\n",sdpbuffer,SerIP);
	sprintf(sdpbuffer,"%ss=SIP Call\r\n",sdpbuffer);
	sprintf(sdpbuffer,"%sc=IN IP4 %s\r\n",sdpbuffer,SockVrs->RecordIP);
	sprintf(sdpbuffer,"%st=0 0\r\n",sdpbuffer);
	sprintf(sdpbuffer,"%sm=audio 4000 RTP\/AVP 0\r\n",sdpbuffer);
	sprintf(sdpbuffer,"%sa=rtpmap:0 PCMU\/8000\r\n",sdpbuffer);
	sprintf(sdpbuffer,"%sa=ptime:20\r\n",sdpbuffer);
	sprintf(sdpbuffer,"%sa=sendonly\r\n\r\n",sdpbuffer);
	

	char buffer[1500];
	sprintf(buffer,"ACK sip:1637@%s:5060;transport=tcp SIP\/2.0\r\n", SockVrs->ipadd);

    time_t t = time(0);  
	char tmp[64];
	strftime(tmp, sizeof(tmp), "Data:%a, %d %b %Y %X GMT",localtime(&t));
	sprintf(buffer,"%s%s\r\n",buffer,tmp);
	sprintf(buffer,"%sFrom: \"%s\" <sip:%s@%s;x-nearend;x-refci=%d;x-nearenddevice=SEP001558E6%d>;tag=%s\r\n",buffer,outNum,outNum,SerIP,callid,outNum,tag);
    sprintf(buffer,"%sAllow-Events: presence, kpml\r\n",buffer);
	sprintf(buffer,"%sContent-Length: %d\r\n",buffer,strlen(sdpbuffer));
    sprintf(buffer,"%sTo: <sip:1637@%s>;tag=%d\r\n",buffer,SockVrs->ipadd,callid);
	sprintf(buffer,"%sContent-Type: application/sdp\r\n",buffer);
	sprintf(buffer,"%sCall-ID: c2738200-ed4187fd-22a8d-%x@%s\r\n",buffer,callid,SerIP);
	sprintf(buffer,"%sVia: SIP/2.0/TCP %s:5060;branch=%s\r\n",buffer,SerIP,branch);
	sprintf(buffer,"%sCSeq: 101 ACK\r\n",buffer);
	sprintf(buffer,"%sMax-Forwards: 70\r\n\r\n",buffer);
	sprintf(buffer,"%s%s",buffer,sdpbuffer);
//	sprintf(buffer,"\r\n\r\n",buffer);

	send(SockVrs->SockClient[point],(char*)buffer,strlen(buffer),0);
 //   strncpy(SockVrs->msgarry[point],buffer,1500);

	OutputDebugStringA(buffer);
	
}




void on_invite_vrs(ThParam Param,char* inNum,char* outNum,int callid)
{
  int n=callid*4;
  char tag1[50];
  char tag2[50];
  char branch1[50];
  char branch2[50];
  char nfend[50];
  int point;
  char buffer[100];
  point=Param.threadnum;
  char tmp[64];
  sprintf(tag1,"762db389-ae92-4496-a9e3-9f760cb8a808-2%d",callid*4+1);
  sprintf(tag2,"762db389-ae92-4496-a9e3-9f760cb8a808-2%d",callid*4+4);

  sprintf(branch1,"z9hG4bK48044f%x", callid*4+1);
  sprintf(branch2,"z9hG4bK48044f%x", callid*4+2);

   porttag[point]=0;
   sprintf (nfend,"x-nearend");
   int suc1=send_invite_message(inNum,outNum,callid,tag1,nfend,branch1,point);
   sprintf (nfend,"x-farend");
   int suc2=send_invite_message(inNum,outNum,callid,tag2,nfend,branch2,point);

  int loop=0;
  char aa[100];


  while (!(SockVrs->bAddr[point]))
  {
	  if (loop==30) 
	  {  
		 if((logfp=fopen("log.txt","at+"))==NULL)
	     {
	  	    MessageBoxA(NULL, "Cannot open log file.\n","Alert",1);
         }
	     else
	     {

             time_t t = time(0);  
	        
	         strftime(tmp, sizeof(tmp), "Time: %a, %d %b %Y %X GMT",localtime(&t));
			 fprintf(logfp,"%s, Missed the record for call: thread:%d, called:%s, Callid:%d \n",tmp, point, outNum,callid);

			 missnum++;
		
	     }
         
	 	 fclose(logfp);
		 send(SockVrs->SockClient[point],SockVrs->msgarry[point],1500,0);

		  break;
	  }

     Sleep(2000);
	 loop++;
  }

  
  sprintf(branch1,"z9hG4bK48044f%x", callid*4+3);
  sprintf(branch2,"z9hG4bK48044f%x", callid*4+4);

  if (loop<30)
  {
    sprintf(aa,"%d",loop);
	OutputDebugStringA(aa);
    send_ack_message(inNum, outNum,callid,tag1,branch1,point);
    send_ack_message(inNum, outNum, callid,tag2,branch2,point);


	sprintf(buffer,"sendudp.exe %s %d 1001.g711",SockVrs->RecordIP,SockVrs->RecordPort[point][0]);

	STARTUPINFOA   si; 
    PROCESS_INFORMATION   piProcess1; 
	 PROCESS_INFORMATION   piProcess2; 
    ZeroMemory(&si,sizeof(si)); 
    si.cb=sizeof(si); 
	si.wShowWindow=SW_MINIMIZE;
	si.dwFlags = STARTF_USESHOWWINDOW;//|STARTF_USESTDHANDLES

    CreateProcessA(NULL, buffer,NULL,NULL,FALSE,0, NULL,NULL,&si,&piProcess1);

   // system(buffer);
    
	sprintf(buffer,"sendudp.exe %s %d 1001.g711",SockVrs->RecordIP,SockVrs->RecordPort[point][1]);
	ZeroMemory(&si,sizeof(si)); 
    si.cb=sizeof(si); 
	si.wShowWindow=SW_MINIMIZE;
	si.dwFlags = STARTF_USESHOWWINDOW;//|STARTF_USESTDHANDLES
	CreateProcessA(NULL, buffer,NULL,NULL,FALSE,0, NULL,NULL,&si,&piProcess2); 

	//system(buffer);
	SockVrs->bAddr[point]=false;
    CloseHandle(piProcess1.hProcess);
	CloseHandle(piProcess1.hThread);

	CloseHandle(piProcess2.hProcess);
	CloseHandle(piProcess2.hThread);




  }





}

void end_vrs_message(const char* inNum,const char* outNum,int callid,const char* tag,const char* branch, int point)
{
	char buffer[1000];


	sprintf(buffer,"BYE sip:1637@%s:5060;transport=tcp SIP/2.0\r\n", SockVrs->ipadd);

    time_t t = time(0);  
	char tmp[64];
	strftime(tmp, sizeof(tmp), "Data:%a, %d %b %Y %X GMT",localtime(&t));
    

	sprintf(buffer,"%s%s\r\n",buffer,tmp);
	//sprintf(buffer,"%sFrom: \"%s\" <sip:%s@%s;x-nearend;x-refci=%d;x-nearenddevice=SEP001558E6%d>;tag=%s\n",buffer,outNum,outNum,SerIP,callid,outNum,tag);
	sprintf(buffer,"%sFrom: \"%s\" <sip:%s@%s;x-nearend;x-refci=%d;x-nearenddevice=SEP001558E6%d>;tag=%s\r\n",buffer,outNum,outNum,SerIP,callid,outNum,tag);
	sprintf(buffer,"%sContent-Length: 0\r\n",buffer);
	sprintf(buffer,"%sUser-Agent: Cisco-CUCM7.0\r\n",buffer);
    sprintf(buffer,"%sTo: <sip:1637@%s>;tag=%d\r\n",buffer,SockVrs->ipadd,callid);
	sprintf(buffer,"%sCall-ID: c2738200-ed4187fd-22a8d-%x@%s\r\n",buffer,callid,SerIP);
	sprintf(buffer,"%sVia: SIP/2.0/TCP %s:5060;branch=%s\r\n",buffer,SerIP,branch);

	sprintf(buffer,"%sP-Preferred-Identity: <sip:%s@%s>\r\n",buffer,outNum,SerIP);
	sprintf(buffer,"%sCSeq: 103 BYE\r\n",buffer);
	sprintf(buffer,"%sMax-Forwards: 70\r\n\r\n",buffer);

	/*
	send(SockVrs->SockClient[point],(char*)buffer,1000,0);

	 Sleep(2000);
	 int it=0;
	 */

	int c=1;
	int flag;
	while (((flag=send(SockVrs->SockClient[point],(char*)buffer,strlen(buffer)+1,0))<0)||(flag==0))
	{
		if (c==15)
		{
             if((logfp=fopen("log.txt","at+"))==NULL)
			{
				MessageBoxA(NULL, "Cannot open log file.\n","Alert",1);
			}
			else
		    { 
 	         strftime(tmp, sizeof(tmp), "Time: %a, %d %b %Y %X GMT",localtime(&t));
			 fprintf(logfp,"%s, Cannot send the BYE to VRS:%d, called:%s, Callid:%d \n",tmp, point, outNum,callid);
		     
			}
			fclose(logfp);
            return;

		}
	  c++;
	  Sleep(2000);
	}
    /* 
	while((it==0)||(it<0))
	{
	 it=send(SockVrs->SockClient[point],(char*)buffer,1000,0);
	 Sleep(1000);
	
	
	};
	*/
	OutputDebugStringA(buffer); 
	strncpy(SockVrs->msgarry[point],buffer,1000);

}


void on_end_vrs(ThParam Param,char* inNum,char* outNum,int callid)
{

	char tag1[50];
	char tag2[50];
	char branch1[50];
	char branch2[50];
	int point;
	point=Param.threadnum;
	sprintf(tag1,"762db389-ae92-4496-a9e3-9f760cb8a808-2%d",callid*4+1);
	sprintf(tag2,"762db389-ae92-4496-a9e3-9f760cb8a808-2%d",callid*4+4);

	sprintf(branch1,"z9hG4bK48044e%x", callid*4+1);
	sprintf(branch2,"z9hG4bK48044e%x", callid*4+2);

	end_vrs_message(inNum,outNum,callid,tag1,branch1,point);
//	Sleep(1000);
	end_vrs_message(inNum,outNum,callid,tag2,branch2,point);



}