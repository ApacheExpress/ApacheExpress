//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

#include "ZzApache.h"

#include <httpd.h>
#include <http_protocol.h>
#include <http_config.h>
#include <http_log.h>
#include <apr_strings.h>

#include <stdio.h>

struct ZzApacheRequest ZzApacheRequestCreate(void *raw) {
  struct ZzApacheRequest rq;
  rq.raw = raw;
  printf("called raw %p\n", raw);
  return rq;
}

#pragma mark Logging

void apz_log_rerror_(const char *file, int line, int module_index,
                     int level, apr_status_t status,
                     const request_rec *r, const char *s)
{
  ap_log_rerror_(file, line, module_index, level, status, r, "%s", s);
}
void apz_log_error_(const char *file, int line, int module_index,
                    int level, apr_status_t status,
                    const server_rec *r, const char *s)
{
  ap_log_error_(file, line, module_index, level, status, r, "%s", s);
}

#pragma mark Bucket Brigade Helpers

apr_status_t apz_fwrite(struct ap_filter_t *f, apr_bucket_brigade *bb,
                        const void *data, apr_size_t nbyte)
{
  // ap_fwrite is a macro in Apache. We could get it working in pure Swift,
  // but it requires a lot of casting :->
  return apr_brigade_write(bb, ap_filter_flush, f, data, nbyte);
}

void apz_brigade_insert_tail(apr_bucket_brigade *bb, apr_bucket *b) {
  APR_BRIGADE_INSERT_TAIL(bb, b);
}
