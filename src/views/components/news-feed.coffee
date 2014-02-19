View      = require "teacup-view"
_         = require "lodash"
_.string  = require "underscore.string"
moment    = require "moment"

debug     = require "debug"
$         = debug "R20:helpers:news_feed"


item      = new View
  components: __dirname
  View (options = {}) ->
    options = _.defaults options,
      url   : "#"
      icons : [ "cogs" ]
      class : "default"
      body  : => @translate "Something happened."
      footer: if options.time? then moment(options.time).fromNow() else ""

    @div class: "panel panel-default", => 
      @a 
        href  : options.url
        class: "panel-body list-group-item", =>
        =>
          @div class: "media", =>
            
            @div class: "pull-left text-" + options.class, =>
              @span class: "media-object fa-stack fa-lg", =>
                @i class: "fa fa-stack-2x fa-" + options.icons[0]
                @i class: "fa fa-stack-1x fa-" + options.icons[1] if options.icons[1]?
            
            @div class: "media-body", =>
              if typeof options.body is "function" then do options.body
              else @p options.body
                
              if options.excerpt? 
                if typeof options.excerpt is "function" then do options.excerpt
                else @div class: "excerpt", =>
                  @strong _.string.stripTags @render => @markdown options.excerpt
          
          @p class: "text-right", => 
            @small options.footer

module.exports = new View
  components: __dirname
  (options = {}) ->
    
    _(options).defaults
      entries: []

    {
      entries
    } = options

    @div class: "news-feed", =>
      for entry in entries

        switch entry.model 
          # Stories related entries
          # -----------------------

          when "Story" then switch entry.action
          
            when "apply" 
              applied = entry.data._entry
              switch applied.action
                when "draft"
                  item 
                    icons   : [ "comment-o", "check" ]
                    url     : "/stories/#{applied.data._id}/"
                    body    : =>
                      @p => 
                        if applied.meta.author._id.equals entry.meta.author._id
                          @translate "%s applied his own draft to a story",
                            entry.meta?.author?.name
                        else
                          @translate "%s applied a draft by %s to a story",
                            entry.meta?.author?.name
                            applied.meta.author.name
                    excerpt : applied.data.text
                    time    : do entry._id.getTimestamp
                    class   : "success"
                when "reference"
                  item
                    icons   : [ "link" ]
                    url     : "/stories/#{applied.data.main?._id or applied.populated "data.main"}/"
                    footer  : "#{entry.meta?.author?.name} applied a question reference to a story."
                    body    : =>
                      @div class: "excerpt", =>
                        @i class: "fa fa-fw text-muted fa-comment" 
                        @em _.string.stripTags @render =>
                          @markdown applied.data.main?.text or "UNPUBLISHED"
                      @div
                        style: """          
                          text-overflow: ellipsis;
                          white-space: nowrap;
                          overflow: hidden;
                        """
                        =>
                          @i class: "fa fa-fw text-muted fa-question-circle" 
                          @strong _.string.stripTags @render =>
                            @markdown applied.data.referenced?.text or "UNPUBLISHED"
                    time    : do entry._id.getTimestamp
                    class   : "info"


          # Questions related entries
          # -------------------------

          when "Question" then switch entry.action

            when "apply" 
              applied = entry.data._entry
              item 
                icons   : [ "plus-circle" ]
                url     : "/questions/#{applied.data._id}/"
                footer  : @cede =>
                  if applied.meta.author._id.equals entry.meta.author._id
                    @translate "%s published his own question",
                      applied.meta.author.name
                  else
                    @translate "%s approved a draft of a question by %s",
                      entry.meta.author.name,
                      applied.meta.author.name
                    
                body    : =>
                  @i class: "fa fa-fw text-muted fa-question-circle" 
                  @strong applied.data.text
                time    : do entry._id.getTimestamp
                class   : "success"
                    
            when "remove" then item
              icons   : [ "question-circle" ]
              url     : "/questions/#{entry.data._id}/"
              body    : "#{entry.meta?.author?.name} removed a question."
              excerpt : entry.data.text
              time    : do entry._id.getTimestamp
              class   : "danger"
            
          
          # Answers related entries
          # -------------------------

          when "Answer" 
            switch entry.action

              when "apply" 
                $ "Answer applied"
                applied   = entry.data._entry
                if not applied.data.question
                  $ "Question (#{applied.populated "data.question"}) was apparently removed"
                  continue

                item 
                  icons   : [ "plus-circle" ]
                  url     : "/questions/#{applied.data.question?._id}##{applied.data._id}/"
                  body    : =>
                    @p =>
                      @i class: "fa fa-fw text-muted fa-question-circle" 
                      @strong applied.data.question.text
                    @p
                      style: """          
                        text-overflow: ellipsis;
                        white-space: nowrap;
                        overflow: hidden;
                      """
                      =>
                        @i class: "fa fa-fw text-muted fa-puzzle-piece" 
                        
                        @em _.string.stripTags @render =>
                          @markdown applied.data.text

                  footer  : @cede =>
                    if applied.meta.author._id.equals entry.meta.author._id
                      @translate "%s published his own answer",
                        applied.meta.author.name
                    else
                      @translate "%s approved a draft of an answer by %s",
                        entry.meta.author.name,
                        applied.meta.author.name
                  class   : "success"

                      
              when "remove"
                if not entry.data.question
                  $ "Question (#{entry.populated "data.question"}) was apparently removed"
                  continue

                if not entry.data.author
                  $ "Author (participant #{entry.populated "data.author"}) was apparently removed"
                  continue

                item
                  icons   : [ "puzzle-piece" ]
                  url     : "/questions/#{entry.data.question}/answers/#{entry.data._id}"
                  body    : "#{entry.meta?.author?.name} removed an answer" # TODO: by #{entry.data.author}
                  excerpt : entry.data.text
                  time    : do entry._id.getTimestamp
                  class   : "danger"
              

          # TODO: only in debug
          else 
            if process.env.NODE_ENV is "development" then item
              time    : do entry._id.getTimestamp

