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
  ap_log_rerror_(file, line, module_index, level, status, r,
                 "%s", s);
}
