%let path=/home/u63575263/SAS M2 SEP/Projet/data;

/******************************************************************/
/*****************Import de la base de données*********************/
/******************************************************************/

proc import out=twitch
    datafile="&path/data_twitch.csv"
    dbms=csv
    replace;
    getnames=YES;
run;


proc import out=sales
    datafile="&path/data_vgsales.csv"
    dbms=csv
    replace;
    getnames=YES;
run;

/******************************************************************/
/*****************Jointure*********************/
/******************************************************************/
data twitch_fixed;
   length game_name $50.; 
   set twitch;
run;

data sales_fixed;
   length game_name $50.; 
   set sales;
run;

proc sort data = twitch_fixed out = twitch_sort;
	by game_name;
run;

proc sort data = sales_fixed out = sales_sort;
	by game_name;
run;


data data;
   merge twitch_sort(in=a) sales_sort(in=b);
   by game_name;
   if a and b; 
run;

/******************************************************************/
/*****************Analyse*********************/
/******************************************************************/
%let var_quanti = current_views total_views_of_this_broadcaster Global_Sales JP_Sales NA_Sales EU_Sales follower_number;
%let var_quali =  broadcaster_language Genre language;

/* Analyse des variables quantitatives avec un histogramme + statistiques descriptives */
proc univariate data=data noprint; 
   var &var_quanti; 
   histogram &var_quanti / normal kernel; 
   inset n mean std / position=ne; 
   title "Analyse de la distribution des variables quantitatives"; 
run;

/* Les résultats des tests de normalité rejettent l'hypothèse H0, ainsi les variables quantitatives ne suivent pas une loi normale */

/* Nombre d'occurence par jeu */

proc sql;
	select game_name, count(stream_ID) as nb_jeux
	from data
	group by game_name
	order by nb_jeux desc;
quit;


/* Modification des labels des variables pour une meilleure lisibilité */
data data_label;
	set data;
	label current_views = "Nombre de vues";
	label Genre = "Genre";
	label total_views_of_this_broadcaster = "Nombre total de vues";
	label broadcaster_name = "Nom du streamer";
run;

/* Calcul du nombre joueurs par genre */
proc sql;
	select Genre, count(stream_ID) as nombre_jeux
	from data
	group by Genre
	order by nombre_jeux desc;
run;
/*  On se rend compte que certains genre de jeu sont très peu joués*/
/* On enlève le genre Adventure et Puzzle car très peu d'occurence <30 */



data data_filter;
	set data_label;
	where Genre ne "Adventure" and Genre ne "Puzzle";
run;


/* Statistiques bivariées */
proc means data=data; 
   var current_views;
   class Genre;
   title 'Statistique descriptives du nombre de vues par genre';
run;

/* Diagramme en barre de la variable Genre */
proc sgplot data = data;
	vbar Genre ;
	title 'Répartition du genre';
run;


proc sgplot data = data_filter;
	label current_views = "Moyenne du nombre de vues";
	vbar Genre / response=current_views stat=mean categoryorder=respasc;
	title "Audience moyenne par genre sur les streams";
run;

/******** Analyse entre la variable exprimant le nombre de vues actuels du stream et le genre du jeu *******/

/* Boxplots du nombre de vues en fonction du genre*/
proc sgplot data=data_filter;
    hbox current_views / category=Genre connect = mean ;
    xaxis max = 50;
    title "Répartition du nombre de vue en fonction du genre";
    
run;

/* On remarque que les moyennes sont différentes en fonction du genre */

/* On fait un test statistique pour confirmer */
proc glm data = data;
	class genre;
	model current_views = Genre /solution;
	means Genre /hovtest = levene;
	title "Test des moyennes du nombre de vues en fonction du genre";
run;
quit;

/* Il n'y a pas d'homogénéité des variances donc le modèle anova n'est pas bon */


/*Quelles moyennes sont différentes?*/
/* On fait un test avec la méthode tukey pour minimiser l'erreur */

proc glm data = data 
		plots(only)=(diffplot(center) controlplot);
	class Genre;
	model current_views = Genre;
	lsmeans Genre /pdiff = all adjust = tukey;
run;
quit;
/* Les moyennes :  */
/* Strategy- Action */
/* Strategy - Fighting */
/* Strategy - Misc*/
/* Strategy - Racing */
/* Strategy - Role-Playing */
/* Strategy - Shooter */
/* Strategy - Sports */
/* Le genre Strategy se différencie le plus */

/* Nous regardons si il y un streamer qui se distingue le plus */
proc sort data=data_filter out=data_sorted_strategy;
    by descending total_views_of_this_broadcaster;
run;

data data_strategy;
	set data_sorted_strategy;
	where Genre ="Strategy";
	if _n_ <= 5; 
run;

proc sgplot data = data_strategy;
	vbar broadcaster_name / response=total_views_of_this_broadcaster categoryorder=respasc;
	title "Les 5 streamers les plus populaires dans le genre Strategy";
run;



/* Régression multiple */
/* Existe-t-il d'autre facteurs pour expliquer le nombre de vues d'un stream? */

/* Matrice de corrélation avec la variable nombre de vues */

proc corr data = data rank plots(only)= scatter (nvar = all ellipse= none);
	var &var_quanti;
	with current_views;
RUN;
/* On voit que le nombre total du streamer est corrélé avec le nombre de vues du stream */

proc glm data = data_filter plots(only)= (contourfit);
	class Genre;
	model current_views = total_views_of_this_broadcaster Genre ;
run;
quit;
/* Le genre n'est pas significatif donc pas de différence de moyenne mais pour le nombre total de vues d'un stream il existe une différence significatif */



/* On poursuit l'analyse bivarié avec les variables qualitatives */
%macro box(dsn= , response = , Charvar  = );
%let i = 1 ;
%do %while(%scan(&charvar,&i,%str( )) ^= %str()) ;
    %let var = %scan(&charvar,&i,%str( ));
    proc sgplot data=&dsn;
        vbox &response / category=&var 
                         grouporder=ascending 
                         connect=mean;
        yaxis max = 50;
        title "&response en fonction des modalités de &var";
    run;
    %let i = %eval(&i + 1 ) ;
%end ;

%mend box;

%box(dsn = data,response = current_views, charvar = &var_quali);



/************************ Analyse des ventes et des pays********************/
/* Agrégation des ventes globales par genre */

proc sql;
    create table sales_by_genre as
    select Genre,
           sum(Global_Sales) as Total_Global_Sales
    from sales
    group by Genre
    order by Total_Global_Sales desc;
quit;


/* Ya t il un lien entre le total des ventes et le nombre de vues */

proc sql;
	create table test_corr as
	select current_views, data.Genre, Total_Global_Sales
	from data left join sales_by_genre 
	on data.Genre = sales_by_genre.genre;
quit;


proc corr data = test_corr rank plots(only)= scatter (nvar = all ellipse= none);
	var Total_Global_Sales;
	with current_views;
RUN;

/* Corrélation proche de 0 = Non */

/* Affichage des résultats */

proc print data=sales_by_genre;
    title "Ventes globales par genre de jeu";
run;

/* Calcul des ventes moyennes par région et par genre */

proc sql;
    create table avg_sales_by_region_genre as
    select Genre,
           mean(NA_Sales) as Avg_NA_Sales,
           mean(EU_Sales) as Avg_EU_Sales,
           mean(JP_Sales) as Avg_JP_Sales,
           mean(Other_Sales) as Avg_Other_Sales
    from sales
    group by Genre
    order by Genre;
quit;

/* Affichage des résultats */

proc print data=avg_sales_by_region_genre;
    title "Ventes moyennes par région et par genre";
run;

/* Calcul des pourcentages de ventes par genre dans chaque région */

proc sql;
    create table sales_percent_by_region as
    select Genre,
           sum(NA_Sales) / (select sum(NA_Sales) from sales) * 100 as Percent_NA_Sales format=8.2,
           sum(EU_Sales) / (select sum(EU_Sales) from sales) * 100 as Percent_EU_Sales format=8.2,
           sum(JP_Sales) / (select sum(JP_Sales) from sales) * 100 as Percent_JP_Sales format=8.2,
           sum(Other_Sales) / (select sum(Other_Sales) from sales) * 100 as Percent_Other_Sales format=8.2
    from sales
    group by Genre
    order by Genre;
quit;

/* Transformation des données pour SGPLOT */

data sales_percent_long;
    set sales_percent_by_region;
    Region = "NA"; Percent = Percent_NA_Sales; output;
    Region = "EU"; Percent = Percent_EU_Sales; output;
    Region = "JP"; Percent = Percent_JP_Sales; output;
    Region = "Other"; Percent = Percent_Other_Sales; output;
    drop Percent_NA_Sales Percent_EU_Sales Percent_JP_Sales Percent_Other_Sales;
run;

/* Création de l'histogramme */

proc sgplot data=sales_percent_long;
    vbar Genre / response=Percent group=Region groupdisplay=cluster datalabel;
    keylegend / title="Région";
    xaxis label="Genre";
    yaxis label="Pourcentage (%)" grid;
    title "Répartition des ventes par genre et par région (en %)";
run;



proc export data=data
    outfile="&path/data_export.xlsx"
    dbms=xlsx
    replace;
run;


/****Analyse de la relation de broadcaster_langage et Global Sales*****/

/* Histogramme montrant la relation entre broadcaster_language et Global_Sales */
proc sgpanel data=data;
    panelby broadcaster_language / layout=rowlattice;
    histogram Global_Sales / scale=proportion;
    density Global_Sales / type=kernel;
    colaxis label="Ventes Mondiales";
    rowaxis label="Proportion";
    title "Distribution des ventes mondiales par langue de diffuseur";
run;

/* Diagramme en barres du nombre de vues en fonction du broadcaster_language */
proc sgplot data=data;
    vbar broadcaster_language / response=Global_Sales stat=mean categoryorder=respasc;
    title "Histogramme des ventes mondiales par langue du diffuseur";
run;

/* Boxplots des ventes mondiales en fonction de broadcaster_language */
proc sgplot data=data;
    hbox Global_Sales / category=broadcaster_language;
    title "Répartition des ventes mondiales en fonction du langage du diffuseur";
run;

/* Test statistique pour comparer les moyennes de Global_Sales en fonction de broadcaster_language */
proc glm data = data plots = diagnostics;
    class broadcaster_language;
    model Global_Sales = broadcaster_language;
    means broadcaster_language /hovtest = levene;
    title "Test des moyennes des ventes mondiales en fonction du langage du diffuseur";
run;
quit;

/* Comparaison des moyennes avec ajustement de Tukey */
proc glm data = data 
        plots(only)=(diffplot(center) controlplot);
    class broadcaster_language;
    model Global_Sales = broadcaster_language;
    lsmeans broadcaster_language / pdiff=all adjust=tukey;
run;
quit;

/* Statistiques descriptives bivariÃ©es */
proc means data=data; 
   var Global_Sales;
   class broadcaster_language;
   title 'Statistiques descriptives des ventes mondiales par langue du diffuseur';
run;

/* Diagramme en barre de la variable broadcaster_language */
proc sgplot data=data;
    vbar broadcaster_language ;
    title 'Répartition des langues des diffuseurs';
run;

/* Utilisation de la macro box pour Global_Sales en fonction du broadcaster_language */
%macro box(dsn= , response = , Charvar  = );
%let i = 1 ;
%do %while(%scan(&charvar,&i,%str( )) ^= %str()) ;
    %let var = %scan(&charvar,&i,%str( ));
    proc sgplot data=&dsn;
        vbox &response / category=&var 
                         grouporder=ascending 
                         connect=mean;
        title "&response à  travers les niveaux de &var";
    run;
    %let i = %eval(&i + 1 ) ;
%end ;
%mend box;

%box(dsn = data, response = Global_Sales, charvar = &var_quali);

/* Matrice de corrÃ©lation avec la variable Global_Sales */
proc corr data = data rank plots(only)=scatter (nvar = all ellipse= none);
    var &var_quanti;
    with Global_Sales;
run;

/* Nombre d'occurrences par langue du diffuseur */
proc sql;
    select broadcaster_language, count(stream_ID) as nb_jeux
    from data
    group by broadcaster_language
    order by nb_jeux desc;
quit;

/* Histogramme montrant la relation entre broadcaster_language et Global_Sales */
proc sgpanel data=data;
    panelby broadcaster_language / layout=rowlattice;
    histogram Global_Sales / scale=proportion;
    density Global_Sales / type=kernel;
    colaxis label="Ventes Mondiales";
    rowaxis label="Proportion";
    title "Distribution des ventes mondiales par langue de diffuseur";
run;

/* Diagramme en barres du nombre de vues en fonction du broadcaster_language */
proc sgplot data=data;
    vbar broadcaster_language / response=Global_Sales stat=mean categoryorder=respasc;
    title "Histogramme des ventes mondiales par langue du diffuseur";
run;

/* Boxplots des ventes mondiales en fonction de broadcaster_language */
proc sgplot data=data;
    hbox Global_Sales / category=broadcaster_language;
    title "Répartition des ventes mondiales en fonction du langage du diffuseur";
run;

/* Test statistique pour comparer les moyennes de Global_Sales en fonction de broadcaster_language */
proc glm data = data plots = diagnostics;
    class broadcaster_language;
    model Global_Sales = broadcaster_language;
    means broadcaster_language /hovtest = levene;
    title "Test des moyennes des ventes mondiales en fonction du langage du diffuseur";
run;
quit;

/* Comparaison des moyennes avec ajustement de Tukey */
proc glm data = data 
        plots(only)=(diffplot(center) controlplot);
    class broadcaster_language;
    model Global_Sales = broadcaster_language;
    lsmeans broadcaster_language / pdiff=all adjust=tukey;
run;
quit;

/* Statistiques descriptives bivariÃ©es */
proc means data=data; 
   var Global_Sales;
   class broadcaster_language;
   title 'Statistiques descriptives des ventes mondiales par langue du diffuseur';
run;

/* Diagramme en barre de la variable broadcaster_language */
proc sgplot data=data;
    vbar broadcaster_language ;
    title 'Répartition des langues des diffuseurs';
run;

/* Utilisation de la macro box pour Global_Sales en fonction du broadcaster_language */

%box(dsn = data, response = Global_Sales, charvar = &var_quali);

/* Matrice de corrÃ©lation avec la variable Global_Sales */
proc corr data = data rank plots(only)=scatter (nvar = all ellipse= none);
    var &var_quanti;
    with Global_Sales;
run;

/* Nombre d'occurrences par langue du diffuseur */
proc sql;
    select broadcaster_language, count(stream_ID) as nb_jeux
    from data
    group by broadcaster_language
    order by nb_jeux desc;
quit;
