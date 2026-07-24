Create Or Alter Function Silver.Fn_Collapse_Spaces (@Input Nvarchar(200))
Returns Nvarchar(200)
As
Begin
	If @Input Is Null Return Null;
	Declare @Result Nvarchar(200) = Ltrim(Rtrim(@Input));
	While Charindex('  ', @Result) > 0
		Set @Result = Replace(@Result, '  ', ' ');
	Return @Result;
End
Go

Create Or Alter Function Silver.Fn_Correct_Known_City (@Raw_City Nvarchar(200))
Returns Nvarchar(200)
As
Begin
	If @Raw_City Is Null Return Null;
	Return
	Case
		-- Garbage / non-city values -> 'unknown', same convention already used in your Sellers/Customers logic
		When @Raw_City In ('bahia','minas gerais','santa catarina','parana','centro','unknown',
			'vendas@creditparts.com.br','04482255','* cidade') Then 'unknown'

		-- Apostrophe restoration patterns
		When @Raw_City Like '% d oeste' Or @Raw_City Like '% doeste' Then Replace(Replace(@Raw_City,' d oeste',' d''oeste'),' doeste',' d''oeste')
		When @Raw_City Like '% do oeste' Then Replace(@Raw_City,' do oeste',' d''oeste')
		When @Raw_City Like '% d agua' Or @Raw_City Like '% dagua' Then Replace(Replace(@Raw_City,' d agua',' d''agua'),' dagua',' d''agua')

		-- Known typos/abbreviations, merged from your Sellers, Customers, and Geolocation lists
		When @Raw_City = 'bh' Then 'belo horizonte'
		When @Raw_City = 'rj' Then 'rio de janeiro'
		When @Raw_City In ('sp','sp / sp','sao paluo','sao pauo','sao paulop','sao paulo - sp','sao paulo / sao paulo','sao paulo sp','são paulo','saopaulo') Then 'sao paulo'
		When @Raw_City In ('ao bernardo do campo','sao bernardo do capo','sbc','sbc/sp') Then 'sao bernardo do campo'
		When @Raw_City In ('ribeirao preto / sao paulo','ribeirao pretp','riberao preto','robeirao preto') Then 'ribeirao preto'
		When @Raw_City In ('rio de janeiro / rio de janeiro','rio de janeiro \rio de janeiro','angra dos reis rj') Then 'rio de janeiro'
		When @Raw_City = 'auriflama/sp' Then 'auriflama'
		When @Raw_City = 'barbacena/ minas gerais' Then 'barbacena'
		When @Raw_City = 'brasilia df' Then 'brasilia'
		When @Raw_City = 'carapicuiba / sao paulo' Then 'carapicuiba'
		When @Raw_City = 'cariacica / es' Then 'cariacica'
		When @Raw_City = 'lages - sc' Then 'lages'
		When @Raw_City = 'maua/sao paulo' Then 'maua'
		When @Raw_City In ('mogi das cruzes / sp','mogidascruzes') Then 'mogi das cruzes'
		When @Raw_City = 'pinhais/pr' Then 'pinhais'
		When @Raw_City = 'santo andre/sao paulo' Then 'santo andre'
		When @Raw_City = 'sao sebastiao da grama/sp' Then 'sao sebastiao da grama'
		When @Raw_City = 'belo horizont' Then 'belo horizonte'
		When @Raw_City = 'cascavael' Then 'cascavel'
		When @Raw_City = 'floranopolis' Then 'florianopolis'
		When @Raw_City = 'mogi das cruses' Then 'mogi das cruzes'
		When @Raw_City = 'portoferreira' Then 'porto ferreira'
		When @Raw_City = 'tabao da serra' Then 'taboao da serra'
		When @Raw_City In ('s jose do rio preto','sao jose do rio pret') Then 'sao jose do rio preto'
		When @Raw_City = 'sando andre' Then 'santo andre'
		When @Raw_City = 'sao jose dos pinhas' Then 'sao jose dos pinhais'
		When @Raw_City = 'arraial d''ajuda (porto seguro)' Then 'arraial d''ajuda'
		When @Raw_City = 'andira-pr' Then 'andira'
		When @Raw_City = 'juzeiro do norte' Then 'juazeiro do norte'
		When @Raw_City = 'paincandu' Then 'paicandu'
		When @Raw_City = 'sao miguel d''oeste' Then 'sao miguel do oeste'
		When @Raw_City In ('santa barbara d oeste','santa barbara d´oeste') Then 'santa barbara d''oeste'
		When @Raw_City = 'maceiao' Then 'maceio'
		When @Raw_City = 'linharesl' Then 'linhares'
		When @Raw_City = 'embuguacu' Then 'embu guacu'
		When @Raw_City = 'vila bela da santssima trindade' Then 'vila bela da santissima trindade'
		When @Raw_City = 'bacaxa (saquarema)   distrito' Then 'bacaxa'
		When @Raw_City = 'praia grande (fundao)   distrito' Then 'praia grande'
		When @Raw_City = 'vitorinos   alto rio doce' Then 'vitorinos'

		Else Silver.Fn_Collapse_Spaces(@Raw_City)
	End;
End
Go