<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:odm="http://www.cdisc.org/ns/odm/v1.3"
                xmlns:def="http://www.cdisc.org/ns/def/v2.1"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                exclude-result-prefixes="odm def xlink">

  <xsl:output method="html" indent="yes" encoding="UTF-8"/>

  <xsl:template match="/">
    <html>
      <head>
        <title>CDISC SDTM Metadata Definition (Define-XML)</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            background-color: #f8fafc;
            color: #1e293b;
            margin: 0;
            padding: 40px;
          }
          .container {
            max-width: 1200px;
            margin: 0 auto;
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
            padding: 40px;
            border: 1px solid #e2e8f0;
          }
          .header {
            border-bottom: 2px solid #e2e8f0;
            padding-bottom: 24px;
            margin-bottom: 32px;
          }
          h1 {
            color: #0f172a;
            font-size: 28px;
            margin: 0 0 8px 0;
            font-weight: 700;
          }
          .subtitle {
            color: #64748b;
            font-size: 16px;
            margin: 0;
            font-weight: 500;
          }
          .metadata-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 24px;
            margin-bottom: 40px;
            background: #f1f5f9;
            padding: 24px;
            border-radius: 8px;
            border: 1px solid #e2e8f0;
          }
          .metadata-item {
            display: flex;
            flex-direction: column;
          }
          .metadata-label {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: #64748b;
            margin-bottom: 6px;
            font-weight: 600;
          }
          .metadata-value {
            font-size: 15px;
            color: #0f172a;
            font-weight: 600;
          }
          h2 {
            color: #0f172a;
            font-size: 20px;
            margin-top: 0;
            margin-bottom: 20px;
            font-weight: 600;
            border-left: 4px solid #0284c7;
            padding-left: 12px;
          }
          table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 32px;
            font-size: 14px;
          }
          th {
            background-color: #0f172a;
            color: #ffffff;
            font-weight: 600;
            text-align: left;
            padding: 14px 16px;
            border: 1px solid #1e293b;
          }
          td {
            padding: 14px 16px;
            border: 1px solid #e2e8f0;
            color: #334155;
            vertical-align: middle;
          }
          tr:nth-child(even) {
            background-color: #f8fafc;
          }
          tr:hover {
            background-color: #f1f5f9;
          }
          .dataset-name {
            font-weight: 700;
            color: #0284c7;
            background-color: #f0f9ff;
            padding: 4px 8px;
            border-radius: 4px;
            border: 1px solid #e0f2fe;
          }
          .badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
          }
          .badge-sdtm {
            background-color: #e0f2fe;
            color: #0369a1;
          }
          .file-link {
            color: #0284c7;
            text-decoration: none;
            font-weight: 600;
          }
          .file-link:hover {
            text-decoration: underline;
          }
          .footer {
            margin-top: 48px;
            border-top: 1px solid #e2e8f0;
            padding-top: 20px;
            font-size: 12px;
            color: #94a3b8;
            text-align: center;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>CDISC Study Tabulation Metadata (Define-XML)</h1>
            <div class="subtitle">FDA Study Data Technical Conformance Guide Compliant</div>
          </div>

          <div class="metadata-grid">
            <div class="metadata-item">
              <span class="metadata-label">Study ID</span>
              <span class="metadata-value"><xsl:value-of select="//odm:GlobalVariables/odm:StudyName"/></span>
            </div>
            <div class="metadata-item">
              <span class="metadata-label">Protocol</span>
              <span class="metadata-value"><xsl:value-of select="//odm:GlobalVariables/odm:ProtocolName"/></span>
            </div>
            <div class="metadata-item">
              <span class="metadata-label">CDISC Standard</span>
              <span class="metadata-value">
                <xsl:value-of select="//odm:MetaDataVersion/@def:StandardName"/> v<xsl:value-of select="//odm:MetaDataVersion/@def:StandardVersion"/>
              </span>
            </div>
            <div class="metadata-item">
              <span class="metadata-label">Define Version</span>
              <span class="metadata-value">v<xsl:value-of select="//odm:MetaDataVersion/@DefineVersion"/></span>
            </div>
          </div>

          <h2>Submitted Tabulation Datasets (SDTM)</h2>
          <table>
            <thead>
              <tr>
                <th style="width: 12%">Domain</th>
                <th style="width: 33%">Description</th>
                <th style="width: 15%">Class</th>
                <th style="width: 25%">Structure</th>
                <th style="width: 15%">Archive File</th>
              </tr>
            </thead>
            <tbody>
              <xsl:for-each select="//odm:ItemGroupDef">
                <tr>
                  <td><span class="dataset-name"><xsl:value-of select="@Name"/></span></td>
                  <td>
                    <strong>
                      <xsl:choose>
                        <xsl:when test="@Name='DM'">Demographics</xsl:when>
                        <xsl:when test="@Name='EX'">Exposure</xsl:when>
                        <xsl:when test="@Name='AE'">Adverse Events</xsl:when>
                        <xsl:when test="@Name='RS'">Disease Response</xsl:when>
                        <xsl:when test="@Name='LB'">Laboratory Test Results</xsl:when>
                        <xsl:when test="@Name='SUPPAE'">Supplemental Adverse Events</xsl:when>
                        <xsl:when test="@Name='TS'">Trial Summary</xsl:when>
                        <xsl:when test="@Name='TA'">Trial Arms</xsl:when>
                        <xsl:when test="@Name='TE'">Trial Elements</xsl:when>
                        <xsl:when test="@Name='CP'">Cell Therapy Product Kinetics</xsl:when>
                        <xsl:when test="@Name='GF'">Graft-Versus-Host Disease Findings</xsl:when>
                        <xsl:otherwise>Tabulation Dataset</xsl:otherwise>
                      </xsl:choose>
                    </strong>
                  </td>
                  <td>
                    <span class="badge badge-sdtm">
                      <xsl:value-of select="@Class"/>
                    </span>
                  </td>
                  <td><xsl:value-of select="@def:Structure"/></td>
                  <td>
                    <xsl:variable name="loc" select="@def:ArchiveLocationID"/>
                    <a class="file-link">
                      <xsl:attribute name="href">
                        <xsl:value-of select="//odm:leaf[@ID=$loc]/@xlink:href"/>
                      </xsl:attribute>
                      <xsl:value-of select="//odm:leaf[@ID=$loc]/def:title"/>
                    </a>
                  </td>
                </tr>
              </xsl:for-each>
            </tbody>
          </table>

          <div class="footer">
            Generated on <xsl:value-of select="substring(//odm:ODM/@CreationDateTime, 1, 10)"/> | Originator: <xsl:value-of select="//odm:ODM/@Originator"/>
          </div>
        </div>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
