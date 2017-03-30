//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

func Main() { // Note: called twice, Apache 2-phase process setup
  serve { (req, res) in
    if req.target == "/echo" {
      guard req.httpVersion == ( 1, 1 ) else {
        /* HTTP/1.0 doesn't support chunked encoding */
        res.writeResponse(status: .httpVersionNotSupported,
                          transferEncoding: .identity(contentLength: 0))
        res.done()
        return .discardBody
      }
      
      res.writeResponse(status: .ok, transferEncoding: .chunked)
      return .processBody { chunk in
        switch chunk {
          case .chunk(let data):
            res.writeBody(data: data)
          case .end:
            res.done()
          default:
            res.abort()
        }
      }
    }
    else {
      print("not echo ...")
      res.writeResponse(status: .notFound,
                        transferEncoding: .identity(contentLength: 0))
      res.done()
      return .discardBody
    }
  }
}
