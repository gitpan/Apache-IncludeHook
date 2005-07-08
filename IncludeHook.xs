#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "mod_perl.h"
#include "mod_include.h"

#define REFCNT_AND_ERROR(buffer,obj,av,hv,rv) \
  MP_TRACE_f(MP_FUNC, "final reference counts: buffer=%d, obj=%d, av=%d, hv=%d\n", \
                      SvREFCNT(buffer), SvREFCNT(obj), \
                      SvREFCNT((SV *)av), SvREFCNT((SV *)hv)); \
  MP_TRACE_f(MP_FUNC, "Apache::IncludeHook - leaving #perl tag due to error\n"); \
  return rv;


static APR_OPTIONAL_FN_TYPE(ap_register_include_handler) *perl_register_include_handler;
static APR_OPTIONAL_FN_TYPE(ap_ssi_get_tag_and_value)    *perl_get_tag_and_value;
static APR_OPTIONAL_FN_TYPE(ap_ssi_parse_string)         *perl_parse_string;

static void handle_arg(request_rec *r, include_ctx_t *ctx,
                       char *tag_val, AV **avp) {

  char parsed_string[MAX_STRING_LEN];

  MP_TRACE_f(MP_FUNC,
             "Apache::IncludeHook - found arg '%s'", 
             tag_val);

  perl_parse_string(r, ctx, tag_val, parsed_string,
                    sizeof(parsed_string), 0);

  MP_TRACE_f(MP_FUNC,
             "Apache::IncludeHook - arg '%s' translated to '%s'", 
             tag_val, parsed_string);

  av_push(*avp, newSVpv(parsed_string, 0));

}

static int handle_perl(include_ctx_t *ctx, apr_bucket_brigade **bb,
                       request_rec *r_bogus, ap_filter_t *f,
                       apr_bucket *head_ptr, apr_bucket **inserted_head)
{
  /* handle <!--#if ... --> statements correctly */
  if( !(ctx->flags & FLAG_PRINTING) ) return APR_SUCCESS;

  /* prepare for 2.1 - get everything from f */
  request_rec *r     = f->r;
  server_rec  *s     = r->server;
  apr_pool_t  *p     = r->pool;

  modperl_handler_t  *handler = NULL;
  apr_bucket         *tmp_buck;
  apr_bucket         *b_new;
  apr_bucket_brigade *bb_new;
  apr_status_t       retval;

  char *tag          = NULL;
  char *tag_val      = NULL;
  char *sub          = NULL;
  char *file         = f->r->filename;
  int seen_sub       = 0;
  int status;

  MP_dTHX;  /* interpreter selection */

  SV     *buffer    = newSV(0);
  SV     *obj       = newSV(0);
  AV     *av        = newAV();
  HV     *hv        = newHV();
  STRLEN length;

  *inserted_head = NULL;

  MP_TRACE_f(MP_FUNC,
             "Apache::IncludeHook - processing #perl tag...");

  MP_TRACE_f(MP_FUNC, "initial reference counts: buffer=%d, obj=%d, av=%d, hv=%d\n",
                      SvREFCNT(buffer), SvREFCNT(obj), 
                      SvREFCNT((SV *)av), SvREFCNT((SV *)hv));

  /* check for Options +IncludesNOEXEC */
  if (ctx->flags & FLAG_PRINTING) {
    if (ctx->flags & FLAG_NO_EXEC) {

      ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r,
                    "#perl used but not allowed in %s", r->filename);

      CREATE_ERROR_BUCKET(ctx, tmp_buck, head_ptr, *inserted_head);
      return APR_SUCCESS;
    }
  }

  /* #perl tag processing */
  while (1) {

    perl_get_tag_and_value(ctx, &tag, &tag_val, 1);

    if (!tag || !tag_val) {
      MP_TRACE_f(MP_FUNC,
                 "Apache::IncludeHook - reached end of tag list...");
      break;
    }

    retval = APR_SUCCESS;
    SPLIT_AND_PASS_PRETAG_BUCKETS(*bb, ctx, f->next, retval);

    if (retval != APR_SUCCESS) {
      ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r,
                    "yikes! splitting the bucket brigade returned %d in %s",
                    retval, file);
  
      REFCNT_AND_ERROR(buffer, obj, av, hv, retval);
    }

    /* skip right over empty values */
    if (!strlen(tag_val)) {
      ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r,
                    "empty value for '%s' parameter to tag 'perl' in %s",
                    tag, file);
  
      CREATE_ERROR_BUCKET(ctx, tmp_buck, head_ptr, *inserted_head);
      REFCNT_AND_ERROR(buffer, obj, av, hv, APR_SUCCESS);
    }

    if (!strcmp(tag, "arg")) {
      handle_arg(r, ctx, tag_val, &av);
    }
    else if (!strcmp(tag, "sub")) {
      /* only one 'sub' parameter allowed perl tag */
      if (seen_sub) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r,
                      "multiple 'sub' parameters to tag 'perl' in %s",
                      file);
  
        CREATE_ERROR_BUCKET(ctx, tmp_buck, head_ptr, *inserted_head);
        REFCNT_AND_ERROR(buffer, obj, av, hv, APR_SUCCESS);
      }
      else {
        MP_TRACE_f(MP_FUNC,
                   "Apache::IncludeHook - found sub '%s'", 
                   tag_val);
  
        handler = modperl_handler_new_from_sv(aTHX_ p,  newSVpv(tag_val, 0));

        if (handler) {
          MP_TRACE_f(MP_FUNC,
                     "Apache::IncludeHook - isolated Perl handler '%s'", 
                      modperl_handler_name(handler));
        }
        else {
          ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r,
                        "couldn't find handler for \"%s\" ",
                        tag_val);
  
          CREATE_ERROR_BUCKET(ctx, tmp_buck, head_ptr, *inserted_head);
          REFCNT_AND_ERROR(buffer, obj, av, hv, APR_SUCCESS);
        }

        seen_sub++;
      } /* end seen_sub */
    } /* end 'sub' */

    else {
      ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r,
                    "unknown parameter \"%s\" to tag 'perl' in %s",
                    tag, file);

      CREATE_ERROR_BUCKET(ctx, tmp_buck, head_ptr, *inserted_head);
      REFCNT_AND_ERROR(buffer, obj, av, hv, APR_SUCCESS);
    }
  }  /* end while */

  if (seen_sub) {
    MP_TRACE_f(MP_FUNC,
               "Apache::IncludeHook - processing handler '%s'", 
               sub);

    /* bless { _r => $r, _b => \$buffer }, $class */
    {
      hv_store(hv, "_r", 2,  modperl_ptr2obj(aTHX_ "Apache2::RequestRec", r), FALSE);
      hv_store(hv, "_b", 2,  newRV_inc(buffer), FALSE);
      obj = newRV_noinc((SV *)hv);
      sv_bless(obj, gv_stashpv("Apache::IncludeHook", TRUE));
    }

    /* tie STDOUT, $class */
    {
      dHANDLE("STDOUT");
      sv_unmagic(TIEHANDLE_SV(handle), 'q');
      sv_magic(TIEHANDLE_SV(handle), obj, 'q', Nullch, 0);
    }

    av_unshift(av, 1);
    av_store(av, 0, obj);

    /* set up rcfg->wbucket */
    modperl_response_init(r);

    if ((status = modperl_callback(aTHX_ handler, p, r, s, av)) != OK) {
      status = modperl_errsv(aTHX_ status, r, s);

      ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r,
                    "Perl subroutine failed with status %i in %s",
                     status, file);

      CREATE_ERROR_BUCKET(ctx, tmp_buck, head_ptr, *inserted_head);
      SvREFCNT_dec(obj);
      SvREFCNT_dec(buffer);
      REFCNT_AND_ERROR(buffer, obj, av, hv, APR_SUCCESS);
    }

    MP_TRACE_f(MP_FUNC,
               "Apache::IncludeHook - handler '%s' returned status '%d'", 
               sub, status);

    length = sv_len(buffer);

    bb_new = apr_brigade_create(p, f->c->bucket_alloc);
    b_new  = apr_bucket_pool_create(SvPV_nolen(buffer), length, 
                                    p, f->c->bucket_alloc);

    MP_TRACE_f(MP_FUNC,
               "Apache::IncludeHook - buffer contained '%d' bytes", 
               length);

    APR_BRIGADE_INSERT_TAIL(bb_new, b_new);
    APR_BRIGADE_INSERT_TAIL(bb_new, apr_bucket_flush_create(f->c->bucket_alloc));

    retval = ap_pass_brigade(f->next, bb_new);

    if ((retval != APR_SUCCESS)) {
      ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r,
                    "yikes! passing the bucket brigade returned %d in %s",
                    retval, file);
  
      CREATE_ERROR_BUCKET(ctx, tmp_buck, head_ptr, *inserted_head);
      REFCNT_AND_ERROR(buffer, obj, av, hv, retval);
    }
  }
  else {
    ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r,
                  "missing 'sub' parameter to tag 'perl' in %s",
                  file);

    CREATE_ERROR_BUCKET(ctx, tmp_buck, head_ptr, *inserted_head);
    REFCNT_AND_ERROR(buffer, obj, av, hv, APR_SUCCESS);
  }

  SvREFCNT_dec(obj);
  SvREFCNT_dec(buffer);

  MP_INTERP_PUTBACK(interp);

  MP_TRACE_f(MP_FUNC, "final reference counts: buffer=%d, obj=%d, av=%d, hv=%d\n",
                      SvREFCNT(buffer), SvREFCNT(obj), 
                      SvREFCNT((SV *)av), SvREFCNT((SV *)hv));

  MP_TRACE_f(MP_FUNC,
             "Apache::IncludeHook - leaving #perl tag successfully\n");

  return APR_SUCCESS;
}


static int register_perl(apr_pool_t *p, apr_pool_t *plog,
                         apr_pool_t *ptemp, server_rec *s)
{

  perl_register_include_handler = APR_RETRIEVE_OPTIONAL_FN(ap_register_include_handler);
  perl_get_tag_and_value        = APR_RETRIEVE_OPTIONAL_FN(ap_ssi_get_tag_and_value);
  perl_parse_string             = APR_RETRIEVE_OPTIONAL_FN(ap_ssi_parse_string);

  if (perl_get_tag_and_value     && 
      perl_parse_string          &&
      perl_register_include_handler) {

      perl_register_include_handler("perl", handle_perl);
  }

  return OK;
}

static const char * const aszPre[] = { "mod_include.c", NULL };

MODULE = Apache::IncludeHook		PACKAGE = Apache::IncludeHook		

PROTOTYPES: DISABLE

  BOOT:
    ap_hook_post_config(register_perl, aszPre, NULL, APR_HOOK_FIRST);
