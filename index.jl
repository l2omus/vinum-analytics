using DataFrames
using Roots
using Gadfly
using SQLite

tm = Theme(minor_label_font_size=20Gadfly.px, major_label_font_size=25Gadfly.px, panel_fill=colorant"#2f2f2f", key_label_color=colorant"#2f2f2f", line_width=3Gadfly.px,
default_point_size=6Gadfly.px, point_label_color=colorant"#15ace4",default_color=colorant"#15ace4", point_label_font_size=18Gadfly.px)

function str(x)
   try
      replace(replace(string(x), "\'", " "), "^", "")
   catch
      "NA"
   end
end

db = SQLite.DB("mailings.sqlite")

# SQLite.query(db, "CREATE TABLE offer
# (offerID INTEGER PRIMARY KEY,
# label varchar(50),
# pr REAL,
# pv REAL,
# kdo REAL,
# n_btls INTEGER,
# exped REAL,
# f_exped REAL,
# rep REAL,
# marge REAL,
# mailingID INTEGER,
# creation varchar(50),
# modification varchar(50))")
#
# SQLite.query(db, "CREATE TABLE mailing
# (mailingID INTEGER PRIMARY KEY,
# titre TEXT,
# nb_tirages INTEGER,
# cout REAL,
# worst REAL,
# expected REAL,
# best REAL)")




#-------------------------------------------------------------------------------
# Définition des types
#-------------------------------------------------------------------------------

type Offre
                offreID::Int
                label::Any
                pr::Number
                pv::Number
                kdo::Number
                n_btls::Int
                exped::Number
                f_exped::Number
                rep::Number
                marge::Number
                mailingID::Int
                creation::DateTime
                modification::DateTime
end

Offre(id, label, pr, pv, kdo, n_btls, exped, f_exped, rep, mailingID) = Offre(id, label, pr, pv, kdo, n_btls, exped, f_exped, rep, n_btls*(0.92*pv-pr)-kdo-exped+f_exped, mailingID, now(), now())
Offre(id::Int) = Offre(id, "Nom de l'offre", 0, 0, 0, 0, 0, 0, 0, 0, 1, now(), now())
Offre(id::Int, mailingID::Int) = Offre(id, "Nom de l'offre", 0, 0, 0, 0, 0, 0, 0, 0, mailingID, now(), now())

function make(o::Offre, db)
                id = SQLite.query(db, "SELECT max(offerID) FROM offer").data[1][1].value
                id += 1
                SQLite.query(db, "INSERT INTO offer
                VALUES($(id), '$(str(o.label))', $(round(o.pr, 4)), $(round(o.pv, 4)), $(round(o.kdo, 4)), $(Int(o.n_btls)), $(round(o.exped,4)), $(round(o.f_exped,4)),
                $(round(o.rep, 4)), $(round(o.marge,4)), $(o.mailingID), '$(now())', '$(now())')")
end

function update(o::Offre, db)
                SQLite.query(db, "UPDATE offer SET offerID = $(o.offreID),
                                label = '$(str(o.label))',
                                pr = $(round(o.pr, 4)),
                                pv = $(round(o.pv, 4)),
                                kdo = $(round(o.kdo, 4)),
                                n_btls = $(Int(o.n_btls)),
                                exped = $(round(o.exped,4)),
                                f_exped = $(round(o.f_exped,4)),
                                rep = $(round(o.rep,4)),
                                marge = $(round(o.marge,4)),
                                modification = '$(now())'
                                WHERE offerID = $(o.offreID)")
end

function delete(o::Offre, db)
                SQLite.query(db, "DELETE FROM offer WHERE offerID = $(o.offreID)")
end

function getO(id, db)
                q = SQLite.query(db, "SELECT * FROM offer WHERE offerID = $(id)")
                o = Offre(id, q.data[2][1].value,
                                q.data[3][1].value,
                                q.data[4][1].value,
                                q.data[5][1].value,
                                q.data[6][1].value,
                                q.data[7][1].value,
                                q.data[8][1].value,
                                q.data[9][1].value,
                                q.data[10][1].value,
                                q.data[11][1].value,
                                DateTime(q.data[12][1].value),
                                DateTime(q.data[13][1].value))
end


# SQLite.query(db, "INSERT INTO offer VALUES(1, 'aaa', 1.2, 2.1, 3.2, 1, 1.2,2.2, 0.3333, 0.21, 1, 'now', 'now')")

type Mailing
                mailingID::Int
                titre::AbstractString
                nb_tirages::Int
                cout::Number
                worst::Number
                expected::Number
                best::Number
                offres::Any
end

Mailing(mailingID, titre, nb_tirages, cout, worst, expected, best) = Mailing(mailingID, titre, nb_tirages, cout, worst, expected, best, Offre[])
Mailing(id) = Mailing(id, "titre", 100000, 30.00, 0.30, 0.50, 0.80, Offre[])

function make(m::Mailing, db)
                id = SQLite.query(db, "SELECT max(mailingID) FROM mailing").data[1][1].value
                id += 1
                SQLite.query(db, "INSERT INTO mailing
                VALUES($(id), '$(str(m.titre))', $(Int(m.nb_tirages)), $(round(m.cout, 4)), $(round(m.worst, 4)),
                $(round(m.expected, 4)), $(round(m.best, 4)))")
                make(Offre(1, id), db)
                return id #getM(id, db)
end

function update(m::Mailing, db)
                SQLite.query(db, "UPDATE mailing SET titre = '$(str(m.titre))',
                                nb_tirages = $(Int(m.nb_tirages)),
                                cout = $(round(m.cout, 4)),
                                worst = $(round(m.worst, 4)),
                                expected = $(round(m.expected, 4)),
                                best = $(round(m.best, 4))
                                WHERE mailingID = $(m.mailingID)")
end

function delete(m::Mailing, db)
                SQLite.query(db, "DELETE FROM offer WHERE mailingID = $(m.mailingID)")
end

##### TRANSFORMER GET OFFER POUR RETOURNER UN ARRAY!

function getM(id, db)
                qm = SQLite.query(db, "SELECT * FROM mailing WHERE mailingID = $(id)")
                m = Mailing(id, qm.data[2][1].value,
                                qm.data[3][1].value,
                                qm.data[4][1].value,
                                qm.data[5][1].value,
                                qm.data[6][1].value,
                                qm.data[7][1].value)
                                #DateTime(qm.data[12][1].value),
                                #DateTime(qm.data[13][1].value))


                n = SQLite.query(db, "SELECT count(offerID) FROM offer WHERE mailingID = $(id)").data[1][1].value
                q = SQLite.query(db, "SELECT * FROM offer WHERE mailingID = $(id)")
                for i in 1:n
                                push!(m.offres,  Offre(q.data[1][i].value,
                                                q.data[2][i].value,
                                                q.data[3][i].value,
                                                q.data[4][i].value,
                                                q.data[5][i].value,
                                                q.data[6][i].value,
                                                q.data[7][i].value,
                                                q.data[8][i].value,
                                                q.data[9][i].value,
                                                q.data[10][i].value,
                                                q.data[11][i].value,
                                                DateTime(q.data[12][i].value),
                                                DateTime(q.data[13][i].value)))
                                #push!(m.offres, o)
                end
                return m
end

function save(m::Mailing)
                make(m, db)
                for o in m.offres
                                make(o, db)
                end
                return "$(m.titre) has been saved"
end


#-------------------------------------------------------------------------------
# Fonctions de format
#-------------------------------------------------------------------------------

corps(x) = size(400px ,40px, Escher.fontsize(22px, lineheight(25px, x)))
tbline(x) = x |> lineheight(3.5vh) |> fontsize(3vh)
resu(x) = textalign(raggedleft, size(180px ,40px, Escher.fontsize(22px, lineheight(25px, x))))
lt(x) = textalign(raggedleft, Escher.fontsize(28px, lineheight(34px, x)))
grostitre(x) = x |> fontcolor("#f56f6f") |> fontsize(6vh) |> lineheight(6vh)
soustitre(x) = x |> fontcolor("#29a4d1") |> fontsize(4vh)

function fornum(x)
                function crop(a)
                                if length(a) > 3
                                                crop(a[1:end-3])*"'"*a[end-2:end]
                                else
                                                a
                                end
                end
                x = @sprintf "%0.2f" x
                res = crop(x[1:end-3])*x[end-2:end]
                if res[1] == '-' && res[2] =='\''
                                res=res[1:1]*res[3:end]
                end
                return res
end


function fornumint(x)
                function crop(a)
                                if length(a) > 3
                                                crop(a[1:end-3])*"'"*a[end-2:end]
                                else
                                                a
                                end
                end
                x = @sprintf "%d" x
                res = crop(x)
                if res[1] == '-' && res[2] =='\''
                                res=res[1:1]*res[3:end]
                end
                return res
end

function fornumintchf(x)
                return string(fornumint(x), " Fr.")
end
function fornumchf(x)
                return string(fornum(x), " Fr.")
end



#-------------------------------------------------------------------------------
# Fonctions d'interface Escher
#-------------------------------------------------------------------------------

function showForm(o::Offre)
                s = sampler()
                form_fields = vbox( Escher.pad(1em, vbox(
                title(1, string(o.label)),
                watch!(s, textinput(string(o.offreID), name=:id, label="id", disabled=true)) |> width(14vw),
                watch!(s, textinput(string(o.label), name=:lb, label="Label")) |> width(14vw),
                watch!(s, textinput(string(o.pr), name=:pr, label="Prix revient")) |> width(14vw),
                watch!(s, textinput(string(o.pv), name=:pv, label="Prix de vente TTC")) |> width(14vw),
                watch!(s, textinput(string(o.kdo), name=:kdo, label="Coût cadeaux")) |> width(14vw),
                watch!(s, textinput(string(o.n_btls), name=:q, label="Nombre bouteilles")) |> width(14vw),
                watch!(s, textinput(string(o.exped), name=:c_exp, label="Frais d'expédition")) |> width(14vw),
                watch!(s, textinput(string(o.f_exped), name=:f_exp, label="Montant expédition facturé")) |> width(14vw),
                watch!(s, textinput(string(o.rep), name=:rep, label="Proportion par commande")) |> width(14vw),
                fontcolor("#fff", fillcolor("#3b3b3b", trigger!(s,  button("Valider", name=:submit))) |> width(14vw)))
                ))
                form = plugsampler(s, form_fields)
                return form
end

function del(o::Offre)
   delete(o, db)
   return "done"
end

function delButton(o::Offre)
   addinterpreter(_ -> del(o), button("Effacer"))
end

function add(o::Offre)
   make(o, db)
   return "done"
end

function addButton(mailingID)
   addinterpreter(_ -> add(Offre(1, "Label", 0, 0, 0, 0, 0, 0, 0, mailingID)), button("Ajouter"))
end

function getForms(offres, inp1, inp2)
                forms = Any[]
                j = 0
                for i in 1:length(offres)
                                 j += 1
                                push!(forms, (showForm(offres[i]) >>> inp1 |> width(14vw)))
                                if !(j==1)
                                push!(forms, (delButton(offres[i]) >>> inp2 |> fillcolor("#a70d18") |> width(14vw)))
                             end
                end
                return forms
end
#-------------------------------------------------------------------------------
# Fonctions de traitement contenu
#-------------------------------------------------------------------------------

function marge_avg(offres)
                return sum([o.marge*o.rep for o in offres])
end
function showMarges(offres)
                marges = Any[]
                for o in offres
                                if o.rep > 0
                                push!(marges, hbox(
                                vbox("Marge $(o.label):") |> width(50vw) |> tbline,
                                vbox(fornumchf(o.marge)) |> width(20vw) |> tbline
                                )|> lt)
                                end
                end
                return marges
end

function showVolumes(offres, r, nb_tirages)
                volumes = Any[]
                for o in offres

                                if o.rep > 0
                                volume(r, o) = r*nb_tirages*o.rep*o.n_btls
                                push!(volumes, hbox(
                                vbox("$(o.label), \# bouteilles") |> width(28vw) |> tbline,
                                vbox("$(fornumint(volume(r[1], o)))") |> width(14vw) |> tbline,
                                vbox("$(fornumint(volume(r[2], o)))") |> width(14vw) |> tbline,
                                vbox("$(fornumint(volume(r[3], o)))") |> width(14vw) |> tbline,
                                )|> lt)
                                end
                end
                return volumes
end

function mailingGUI(minput)


                inp1 = Input(Dict{Any,Any}(:lb => value(minput).offres[1].label,
                                                :c_exp=>value(minput).offres[1].exped,
                                                :submit=>Escher.LeftButton(),
                                                :q=>value(minput).offres[1].n_btls,
                                                :pr=>value(minput).offres[1].pr,
                                                :rep=>value(minput).offres[1].rep,
                                                :_trigger=>:submit,
                                                :pv=>value(minput).offres[1].pv,
                                                :kdo=>value(minput).offres[1].kdo,
                                                :f_exp=>value(minput).offres[1].f_exped,
                                                :id=>1))

                of = Input(value(minput).offres)
                tirages_s = Input(value(minput).nb_tirages/1000)
                cu_mailing_s = Input(value(minput).cout/(value(minput).nb_tirages))
                obj_w = Input(100*value(minput).worst)
                obj_s = Input(100*value(minput).expected)
                obj_b = Input(100*value(minput).best)
                titre_s = Input(value(minput).titre)

                inp2= Input("")
                inp3= Input("")

               obj_w2 = consume(obj_w) do o
                   o/100
               end

               obj_s2 = consume(obj_s) do o
                   o/100
               end

               obj_b2 = consume(obj_b) do o
                   o/100
               end

               tirages_s2 = consume(tirages_s) do t
                   t*1000
               end

                mailing_sig = consume(tirages_s2, cu_mailing_s, obj_w2, obj_s2 ,obj_b2, titre_s, of, inp2, inp3) do tirages, cu_mailing, objw, obj, objb, titre, ofs, inu, inu3
                                mailing = Mailing(value(minput).mailingID, titre, tirages, tirages * cu_mailing, objw, obj, objb)
                                update(mailing, db)
                                mailing
                end

                o_sig = consume(inp1) do offre1
                                o =  getO(int(offre1[:id]), db)
                                o.label = offre1[:lb]
                                o.pr = float(offre1[:pr])
                                o.pv = float(offre1[:pv])
                                o.kdo = float(offre1[:kdo])
                                o.n_btls = float(offre1[:q])
                                o.exped = float(offre1[:c_exp])
                                o.f_exped = float(offre1[:f_exp])
                                o.rep = float(offre1[:rep])
                                o.marge = o.n_btls*(0.92*o.pv-o.pr)-o.kdo-o.exped+o.f_exped
                                update(o, db)
                                "done"
                end

                mailing_s = merge(mailing_sig, minput)

                box_mailing = consume(o_sig, mailing_s, of) do o, mailing, ofs


                                mailing=getM(mailing.mailingID, db)
                                #TEMP
                                cu_mailing = mailing.cout/mailing.nb_tirages
                                objw = mailing.worst
                                obj = mailing.expected
                                objb = mailing.best

                                #push!(offres, o)
                                #push!(offres_s, Input(Dict{Any,Any}(:c_exp=>12.90,:submit=>Escher.LeftButton(),:q=>12,:pr=>3.76,:rep=>0.333,:_trigger=>:submit,:pv=>9.15,:kdo=>0.0,:f_exp=>12.0)))
                                offres = ofs

                                gain_bar = marge_avg(mailing.offres)
                                mailing.cout = mailing.nb_tirages*cu_mailing
                                gain_tot(r, mailing) = mailing.nb_tirages*r*marge_avg(mailing.offres)-mailing.cout
                                bep = roots(x -> gain_tot(x, mailing))
                                bep = length(bep) == 0 ? [10] : bep
                                beps = @sprintf("%0.3f", bep[1]*100)
                                beps = beps*"%"

                                bepcom = bep[1]*mailing.nb_tirages
                                #
                                df = DataFrame(Rendement=[r for r in 0:0.001:0.02], Gain=[gain_tot(r, mailing) for r in 0:0.001:0.02])
                                #
                                plot1 = plot(layer(df, x=:Rendement, y=:Gain, Geom.line), layer(x=bep, y=[0], label=["BEP ($beps)"] ,Geom.point, Geom.label), Guide.title("Gain et perte"), Scale.y_continuous(format=:plain), tm)
                                #
                                #volume_vin(r) = r*mailing.nb_tirages*(float(offreA[:rep])*float(offreA[:q])+float(offreB[:rep])*float(offreB[:q]))
                                #
                                #volume(r, o) = r*mailing.nb_tirages*o.rep*o.n_btls
                                #df2 = DataFrame(Rendement=[r for r in 0:0.001:0.02], Bouteilles=[volume_vin(r) for r in 0:0.001:0.02])
                                #plot2 = plot(df2, x=:Rendement, y=:Cartons, Geom.line, Guide.title("Volume vin"), Scale.y_continuous(format=:plain))
                                #
                                cpo(r, m::Mailing) = mailing.cout/(r*mailing.nb_tirages)#-gain_tot(r)/(r*mailing.nb_tirages)
                                #
                                df3 = DataFrame(Rendement=[r for r in 0.0008:0.0001:0.02], CPO=[cpo(r, mailing) for r in 0.0008:0.0001:0.02])
                                plot3 = plot(layer(df3, x=:Rendement, y=:CPO, Geom.line), layer(x=[bep], y=[0], label=["BEP ($beps)"] ,Geom.point, Geom.label),Guide.title("Cost per order"), Scale.y_continuous(format=:plain), tm)

                                vbox(
                                hbox(vbox(
                                Escher.pad(1em,vbox(
                                vbox(
                                #addinterpreter(_ -> save(mailing), button("Sauvegarder")) >>> s |> fillcolor("#22c21f"),
                                "Paramètres" |> soustitre,
                                textinput("$(mailing.titre)", label="Titre") >>> titre_s |> width(14vw),
                                "Nombre tirages (en milliers):",
                                slider(0:300, name="tirage", value=mailing.nb_tirages/1000) >>> tirages_s,
                                "Coût unitaire mailing (CHF):",
                                slider(0:0.01:4, name="cmailing", value=cu_mailing) >>> cu_mailing_s,
                                "Worst case (%):",
                                slider(0:0.01:4, name="objectif", value=100*mailing.worst) >>> obj_w,
                                "Rendement cible (%):",
                                slider(0:0.01:4, name="objectif", value=100*mailing.expected) >>> obj_s,
                                "Best case (%):",
                                slider(0:0.01:4, name="objectif", value=100*mailing.best) >>> obj_b,
                                vskip(1em),

                                vbox(
                                getForms(mailing.offres, inp1, inp2)...,
                                addButton(mailing.mailingID) >>> inp3 |> fillcolor("#a7930d") |> width(14vw),
                                vbox(Escher.pad(1em, vbox(
                                vskip(2em),

                                ))))) |> width(20vw),
                                ))|> fillcolor("#dff4ff")) |> height(94vh) |> clip(auto) ,

                                vbox(
                                Escher.pad(2em, vbox(
                                hbox(
                                vbox(
                                mailing.titre |> fontsize(8vh) |> width(80vw) |> grostitre,
                                vskip(1em),
                                "Analyse de rentabilité" |> soustitre,
                                vskip(1em),
                                hbox(
                                vbox("Nombre de tirages:") |> width(50vw) |> tbline,
                                vbox(fornumint(mailing.nb_tirages)) |> width(20vw) |> tbline
                                ) |> lt,
                                hbox(
                                vbox("Coût par tirage:") |> width(50vw) |> tbline,
                                vbox(fornumchf(cu_mailing)) |> width(20vw) |> tbline
                                ) |> lt,
                                hbox(
                                vbox("Coût total mailing:") |> width(50vw) |> tbline ,
                                vbox(fornumintchf(mailing.cout)) |> width(20vw) |> tbline
                                ) |> lt,
                                showMarges(mailing.offres)...,
                                hbox(
                                vbox("Marge moyenne par commande:") |> width(50vw) |> tbline ,
                                vbox(fornumchf(gain_bar)) |> width(20vw) |> tbline
                                ) |> lt,
                                hbox(
                                vbox("BEP (Taux de réponse):") |> width(50vw) |> tbline ,
                                vbox(beps) |> width(20vw) |> tbline
                                ) |> lt,
                                hbox(
                                vbox("BEP (nombre de commandes):") |> width(50vw) |> tbline ,
                                vbox(fornumint(bepcom)) |> width(20vw) |> tbline
                                )|> lt
                                ) |> width(70vw)

                                ),

                                "Projections" |> soustitre,
                                vskip(1em),
                                hbox(
                                vbox("") |> width(28vw),
                                vbox("Minimum") |> width(14vw),
                                vbox("Attendu") |> width(14vw),
                                vbox("Maximum") |> width(14vw),
                                ) |> lt |> tbline,
                                hbox(
                                vbox("Rendement:") |> width(28vw),
                                vbox("$(fornum(mailing.worst * 100)) %") |> width(14vw),
                                vbox("$(fornum(mailing.expected * 100)) %") |> width(14vw),
                                vbox("$(fornum(mailing.best * 100)) %") |> width(14vw),
                                )|> lt |> tbline,
                                hbox(
                                vbox("Nombre Commandes") |> width(28vw),
                                vbox("$(fornumint(mailing.worst*mailing.nb_tirages))") |> width(14vw),
                                vbox("$(fornumint(mailing.expected*mailing.nb_tirages))") |> width(14vw),
                                vbox("$(fornumint(mailing.best*mailing.nb_tirages))") |> width(14vw),
                                )|> lt |> tbline,
                                hbox(
                                vbox("Gain/Perte:") |> width(28vw),
                                vbox("$(fornumintchf(gain_tot(mailing.worst, mailing)))") |> width(14vw),
                                vbox("$(fornumintchf(gain_tot(mailing.expected, mailing)))") |> width(14vw),
                                vbox("$(fornumintchf(gain_tot(mailing.best, mailing)))") |> width(14vw),
                                )|> lt |> tbline,
                                hbox(
                                vbox("Cost per order:") |> width(28vw),
                                vbox("$(fornumintchf(cpo(mailing.worst, mailing)))") |> width(14vw),
                                vbox("$(fornumintchf(cpo(mailing.expected, mailing)))") |> width(14vw),
                                vbox("$(fornumintchf(cpo(mailing.best, mailing)))") |> width(14vw),
                                )|> lt |> tbline,
                                showVolumes(mailing.offres, [mailing.worst, mailing.expected, mailing.best], mailing.nb_tirages)...,
                                vbox(
                                vskip(5em),
                                hbox(
                                plot1, plot3)
                                )
                                ))



                                )|>width(80vw))
                                )
                end

                return box_mailing
end

function printview(m::Mailing)
                vbox("coucou")
end


#-------------------------------------------------------------------------------
# Initialisation des collections
#-------------------------------------------------------------------------------


function ticker_list(selected, current_ticker, tickers)
                list = tickers
    map(list) do t
        item = (t == selected ? fillcolor("#9ba", Escher.pad(0.5em, t)) : Escher.pad(0.5em, t))
        constant(t, clickable(item)) >>> current_ticker
    end |> vbox |> clip(auto) |> size(100vw, 80vh)
end


#-------------------------------------------------------------------------------
# Escher Main Section
#-------------------------------------------------------------------------------


main(window) = begin
                push!(window.assets, "widgets")
                push!(window.assets, "layout2")

                #sam = Offre(1, "12xRothschild", 3.15, 9.95, 0, 12, 12.90, 9, 0.33333, 155)
                #sam2 = Offre(2, "24xRothschild", 3.15, 9.95, 4.40, 24, 12.90, 0, 0.66666, 155)
                #make(sam, db)
                #make(sam, db)
                # sam3 = Offre(3)
                # sam4 = Offre(4)
                # sam5 = Offre(5)
                # sam6 = Offre(6)
                # sam7 = Offre(7)
                # sam8 = Offre(8)
                # sam9 = Offre(9)
                # sam10 = Offre(10)
                #offres = [sam, sam2] #, sam3, sam4, sam5, sam6, sam7, sam8, sam9, sam10]
                #mailing =  Mailing(155, "Prospection 16", 200, 120000, 0.5, 0.8, 1.0, offres)
                #make(mailing, db)

                current_ticker = Input("1")

                function getTickers()
                                q = SQLite.query(db, "SELECT titre, mailingID FROM mailing ORDER BY mailingID DESC")
                                tickers = [string(q.data[2].values[i], "-", q.data[1].values[i]) for i in 1:length(q.data[2].values)] # for i in 1:length(q.data[2].values
                                lift((x) -> ticker_list(x, current_ticker, tickers), current_ticker)
                end

                mID = Input(1)
                #cb = Input(false)
                mkid = Input(1)



                boxi = vbox(
                                consume(mkid) do mk
                                                getTickers()
                                end
                                ,
                                addinterpreter(x -> make(Mailing(1), db), button("Créer un nouveau mailing")) >>> mkid
                                )

                mID = consume(current_ticker) do c
                                parse(Int,split(c, '-')[1])
                end

                minput = consume(mID) do id
                                getM(id, db)
                end


                ti, pi = wire(tabs(["liste", "unique"]),
                pages([mailingGUI(minput), boxi]), :tabschannel, :selected)


                vbox(toolbar([icon("track-changes") |> fontcolor("#fff"), "Vinum" |> fontsize(4vh) |> lineheight(6vh), flex(), ti])|> height(6vh),
                pi
                     )


end
