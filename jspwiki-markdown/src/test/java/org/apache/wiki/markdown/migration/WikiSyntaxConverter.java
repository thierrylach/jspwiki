/*
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
 */
package org.apache.wiki.markdown.migration;

import org.apache.commons.lang3.ArrayUtils;
import org.apache.wiki.TestEngine;
import org.apache.wiki.api.core.Attachment;
import org.apache.wiki.api.core.Context;
import org.apache.wiki.api.core.ContextEnum;
import org.apache.wiki.api.core.Engine;
import org.apache.wiki.api.core.Page;
import org.apache.wiki.api.exceptions.WikiException;
import org.apache.wiki.api.spi.Wiki;
import org.apache.wiki.attachment.AttachmentManager;
import org.apache.wiki.htmltowiki.HtmlStringToWikiTranslator;
import org.apache.wiki.markdown.migration.parser.JSPWikiToMarkdownMarkupParser;
import org.apache.wiki.pages.PageManager;
import org.apache.wiki.plugin.PluginManager;
import org.apache.wiki.render.RenderingManager;
import org.jdom2.JDOMException;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

import static org.apache.wiki.TestEngine.with;


/**
 * <p>Class used to autogenerate the initial set of markdown files, derived from the ones with jspwiki syntax, as part
 * of the build,</p>
 * <p>Can be used as a starting point to develop more complex converters from jspwiki to markdown syntax f.ex, to also
 * convert page history, retain original authors, etc.</p>
 */
class WikiSyntaxConverter {

    @ParameterizedTest
    @ValueSource( strings = { "de", "en", "es", "fi", "fr", "it", "nl", "pt_BR", "ru", "zh_CN" } )
    void jspwikiToMarkdownConverter( final String lang ) throws Exception {
        final File target = new File( "../jspwiki-wikipages/" + lang + "/src/main/resources/markdown" );
        target.delete();
        translateJSPWikiToMarkdown( lang );
        Arrays.stream( ArrayUtils.nullToEmpty( target.listFiles( ( dir, name ) -> name.endsWith( ".properties" ) ), File[].class ) )
              .forEach( file -> file.delete() );
    }

    void translateJSPWikiToMarkdown( String lang ) throws JDOMException, IOException, ReflectiveOperationException, WikiException {
        final Engine jspw = buildEngine( "jspwiki", "../jspwiki-wikipages/" + lang + "/src/main/resources" );
        final Engine md = buildEngine( "markdown", "../jspwiki-wikipages/" + lang + "/src/main/resources/markdown" );
        jspw.getManager( PluginManager.class ).enablePlugins( false );

        final Collection< Page > pages = jspw.getManager( PageManager.class ).getAllPages();
        for( final Page p : pages ) {
            final Context context = Wiki.context().create( jspw, p );
            context.setRequestContext( ContextEnum.PAGE_NONE.getRequestContext() );
            context.setVariable( Context.VAR_WYSIWYG_EDITOR_MODE, Boolean.TRUE );
            final String pagedata = jspw.getManager( PageManager.class ).getPureText( p.getName(), p.getVersion() );
            final String html = jspw.getManager( RenderingManager.class ).textToHTML( context, pagedata, null, null, null, false, false );
            final String syntax = new HtmlStringToWikiTranslator( md ).translate( html );
            final Context contextMD = Wiki.context().create( md, p );
            md.getManager( PageManager.class ).saveText( contextMD, clean( syntax ) );
            final List< Attachment > attachments = jspw.getManager( AttachmentManager.class ).listAttachments( p );
            for( final Attachment attachment : attachments ) {
                final InputStream bytes = jspw.getManager( AttachmentManager.class ).getAttachmentStream( context, attachment );
                md.getManager( AttachmentManager.class ).storeAttachment( attachment, bytes );
            }
        }
    }

    Engine buildEngine( final String syntax, final String pageDir ) {
        return TestEngine.build( with( "jspwiki.fileSystemProvider.pageDir", pageDir ),
                                 with( RenderingManager.PROP_PARSER, JSPWikiToMarkdownMarkupParser.class.getName() ), // will be overwritten if jspwiki.syntax=markdown
                                 with( "jspwiki.test.disable-clean-props", "true" ),
                                 with( "jspwiki.workDir", "./target/workDir" + syntax ),
                                 with( "appender.rolling.fileName", "./target/wiki-" + syntax + ".log" ),
                                 with( "jspwiki.cache.enable", "false" ),
                                 with( "jspwiki.syntax", syntax ) );
    }

    String clean( final String wikiSyntax ) {
        return wikiSyntax;
    }

}
