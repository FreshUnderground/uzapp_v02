-- Migration Data Export with Owner ID

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE products;

TRUNCATE TABLE shops;

TRUNCATE TABLE categories;

SET FOREIGN_KEY_CHECKS = 1;


-- Categories

INSERT INTO categories (name, icon) VALUES ('TECHNOLOGIE', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/category%2Ftech.png?alt=media&token=a99064b5-3889-4403-9a12-c12e7eae73f3');

INSERT INTO categories (name, icon) VALUES ('AUTOMOBILE', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/category%2Fauto.png?alt=media&token=99f554f6-416b-4022-a6c3-2057213af6ea');

INSERT INTO categories (name, icon) VALUES ('QUINCAILLERIE', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/category%2Fquicaillerie.png?alt=media&token=9e9e0775-5fba-4137-a508-afc2d0b5686a');

INSERT INTO categories (name, icon) VALUES ('HABILLEMENT', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/category%2Fhabillement.png?alt=media&token=7fb75dce-1048-4302-9ab7-a82e434e4dcf');

INSERT INTO categories (name, icon) VALUES ('AUTRES', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/category%2Fpngegg%20(24).png?alt=media&token=7179b989-155a-406d-9d1c-04c9c2efb13a');

INSERT INTO categories (name, icon) VALUES ('FAST FOOD', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/category%2Ffood.png?alt=media&token=cb73f26a-e5cc-4231-ad68-4f68fd3ea548');

INSERT INTO categories (name, icon) VALUES ('IMMOBILIER', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/category%2Flocation.png?alt=media&token=9d596e81-c0c4-47ac-bbd3-a0672e1a5551');


-- Shops

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('SHARON', 'butembo , galerie du marché', 'vente des habillement', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_IMG_20240628_184433.jpg?alt=media&token=af8b9fd5-5ef3-47d8-a299-45ce5b5bf5c4', '+243810766933', '+243810766933');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('POWER TECH', 'galerie de luxe n°25', 'vente ordinateur, téléphone et accessoires ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243811887677', '+243811887677');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('KITAMBALA DENIS', 'galerie Élizabeth n 35', 'vente outil électronique accessoires', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243812854735', '+243812854735');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LV FASHION ', 'gallerie mukondi', 'vente des habits ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_Screenshot_20240519-194038.png?alt=media&token=ffa762e3-3c8a-4cde-91e7-90b30d278f35', '+243813557132', '+243813557132');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('BASHARMA', 'av beni', 'vente de chousur ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243813733000', '+243813733000');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('TOUT EST GRACE', 'butembo, galerie fataki ', 'vente habits', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243813901957', '+243813901957');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CLASSIC SHOP', 'av de l''eglise', 'vente montre', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243816993446', '+243816993446');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MAISON ENTRE-NOUS', 'avenue mususa', 'vente de whisky buffalo', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243817284839', '+243817284839');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('BILALY DESIGN', 'Beni Ville', 'Design graphique', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_PROFIL%20FB.jpg?alt=media&token=7fc94fc6-9195-41e5-bef7-27fc91906d03', '+243819482397', '+243819482397');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ WILL BUSINESS', 'galerie nzanzu n032', 'vente des téléphones et accessoires', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243822016942', '+243822016942');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LA GRACE', 'galerie mbanga', 'vente d''habillement', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243823066980', '+243823066980');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('JULIE MULUMBA', 'ruhenda', 'dépôt cima', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243824097098', '+243824097098');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('TAPARI', 'rue présidentielle, galerie sion n3', 'vente moteurs, télévision et accessoires', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1000506047.jpg?alt=media&token=98ee8528-1888-4947-82f0-b6a5b5fd8c0e', '+243825294334', '+243825294334');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MAISON MASIMENGO ', 'rue kin', 'habillement ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243827074411', '+243827074411');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('TOUT VIENT DE DIEU', 'galerie Joël,n 9', 'vente d''habits', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243827654725', '+243827654725');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ MUHINDO MUHASA', 'galerie kitsa furaha2,n°128', 'vente des habits style homme', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243828041472', '+243828041472');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('SIVIHWA', 'butembo galerie nzanzu,n41', 'vente des téléphones et accessoires', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243829537110', '+243829537110');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('ETS. MUSANGANIA MATHE JOHN', 'Rue Kinshasa, Bâtiment Masumbuko Gaspard, Nº. 32', 'Vente des Lubrifiants.', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243830709296', '+243830709296');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('NEMALI', 'Butembo,av ngulo n°23', 'vente des habits ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243831414271', '+243831414271');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ ZAWADI', 'rue kin, galerie mbanga n 31', 'vente Pièces électroniques', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243833695500', '+243833695500');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('DANIEL MAKASI', 'rue Kinshasa', 'vente meubles et divan', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243833916255', '+243833916255');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('SHOULAMMITE ', 'galerie kihuhania', 'vente perruques ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243834301873', '+243834301873');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('FLORFASHION', 'av beni', 'habillement', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243835859346', '+243835859346');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LK SHOP', 'galerie muhyana', 'ventes de mèche,plantes,perruque et outre Axcesoire', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243836416672', '+243836416672');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHRIST EST VIVANT ', 'galerie kihuhanya ', 'vente des écrans, câble, écouter, téléphone et autres accessoires ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243836750625', '+243836750625');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ EZECKIAS', 'galerie kitsa furaha2,n°109', 'ventes des habits et souliers ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1000027340.jpg?alt=media&token=264572ec-5040-4e30-9417-1548574a4456', '+243842286271', '+243842286271');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LAPRINELLE', 'av,mikundi', 'vente de penture', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243844232489', '+243844232489');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LA REINE TSONGO', 'av lubero', 'Maison d''habillement', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243848664025', '+243848664025');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('FURAHA FASHION', 'galerie kyanamire', 'commerciale', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243850637206', '+243850637206');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MTK', 'Av Matokeo', '', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243851780126', '+243851780126');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ PATRICK', 'galerie kisunga,n B21', 'vente téléphone et accessoires', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243852016065', '+243852016065');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHALLY CAMPANY', 'rue kin,bat kyamolova n ', 'vente Pièces  de  rechange moto original haojue ,rue kini vers Gallery kisune .', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243857881641', '+243857881641');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('BM COSMETIC', 'Ville de Butembo,Avenue Rwenzori, Bâtiment Henri', 'Vente en gros et détail des produits cosmétiques', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_IMG-20230816-WA0001.jpg?alt=media&token=1f6f00b3-3a2f-4122-b7aa-128c8c0897a0', '+243891541846', '+243891541846');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('KALYFASHION', 'galerie la vérité N°52', 'achat, vente et livraison des produits aux clients ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243893250379', '+243893250379');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('K.L', 'galerie  Henry  pierre are ', 'vente des téléphones ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_Screenshot_20240623-184213_WhatsAppBusiness.jpg?alt=media&token=7923bc84-9a85-46d9-9519-7bc7e2c4ab50', '+243893813625', '+243893813625');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('AMANI ', 'galerie muhyana ', 'vente de radio ,penneau et autres accessoires ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243894549026', '+243894549026');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('ANWA BOUTIQUE', 'galerie lulengo', 'vente montre', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243894885314', '+243894885314');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('BARAKA SERVICE', 'AV LUBERO', 'Vente des vestes', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243895570930', '+243895570930');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('DEV', 'rue Kinshasa ', 'vente meubles ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243896293805', '+243896293805');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('GOD PLANS ', 'BENI MATONGE', '2312@@', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243898429006', '+243898429006');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MAISON TECHNIQUE MAKASI', 'rue kin', 'garnissage ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243970128303', '+243970128303');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MELKA ', 'galerie Joël ', 'vente de anciete ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1000137255.jpg?alt=media&token=8f41eac3-505f-492e-a3bd-e465de8780e8', '+243970293398', '+243970293398');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('DE L''ESPOIR ', 'galerie Élisabeth n 24', 'ventes des souliers et accessoires ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243970393788', '+243970393788');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('PALMUS SHOP', 'bunia', 'vente accessoires ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243970413058', '+243970413058');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('KTP COMPAGNY', 'avenue matokeo référence banque du sang', 'Nous vendons des téléphonesp et canapés de qualité', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_f330c39b62964199ba0c2933af15f145.jpg?alt=media&token=e1723620-d1c2-42e3-9860-e2d6e80c2787', '+243970501671', '+243970501671');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('FLORSON', 'Avenue buyora', 'vente des habits, parfum et tapis', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243970974501', '+243970974501');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('M.T. M', 'rue kinshasa', 'vents Meuble, furniture  d''omestique ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_FB_IMG_17187136336686200.jpg?alt=media&token=3bd8e28b-63ed-4dd4-a9ee-7070aa21052f', '+243971142794', '+243971142794');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES (' CHEZ MAMAN LAREINE ', 'Bbo av ngulo ', 'vente semoule ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243971223342', '+243971223342');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('JM FASHION', 'avenue goma', 'vente des habis et chaussures', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243971479052', '+243971479052');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LA PRUNELLE', 'av''mikundi', 'vente penture', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+24397184872', '+24397184872');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MATHE FASHION ', 'av beni', 'vente des abis ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243971875077', '+243971875077');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('ARIS', 'galerie mukondi numéro 13', 'vente des habits style homme lux', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243972094625', '+243972094625');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('FASHION MWIRA ', 'Galerie muhyana n°bc3', 'vente des bijoux,sac à main  et accessoires téléphone ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243972124672', '+243972124672');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ KAVIRA RACHEL ', 'galerie feli', 'ventes  des pagnes', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243972155851', '+243972155851');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('KALERE', 'avenue matekeo,n 52', 'ventes des radios', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243972380171', '+243972380171');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MARTHA ', 'galerie kyanamire numéro 8 ', 'ventes des chossure ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1000048158.jpg?alt=media&token=9b4a72d5-310c-432d-821c-2c30f6e190bd', '+243972417493', '+243972417493');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ JOSÉPHINE', 'bâtiments bonne année', 'vente des habits mixte', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243972736674', '+243972736674');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LAD', 'galerie kyanamire', 'vente soulier, montre, bijoux ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243972791964', '+243972791964');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('ELIZA CHOPING', 'kyanamire numéro 38', 'bijouterie ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243972884061', '+243972884061');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LINDA MWIKA', 'rue kinshasa', 'atelier ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243972960821', '+243972960821');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MAXIME CHONGO', 'galerie Joël ', 'sec a mais ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243973102757', '+243973102757');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MANYI MODE', 'avenue lipumbu', 'atelier fanshion', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243973141181', '+243973141181');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MUNGU NI JIBU', 'Rue kis', 'Menuiserie moderne ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243973333015', '+243973333015');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('EBENEZER ', 'av.du centre ', 'vente pièces de rechange ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243973607689', '+243973607689');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('JOSH BIJOUX', 'galerie henry pierrard', 'bijouterie', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243973946420', '+243973946420');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('KUBUYAMARKET', 'Londo', 'Formation en logiciel CAO et DAO ex: SketchUp,autocad, revit,lumion, robot structure,....', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243973972141', '+243973972141');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('ETS KANYABOSS ', 'AV MASISI ', 'HABILLEMENT ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243974020193', '+243974020193');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('AU ROYALE BUSINESS ', 'rue kin, bâtiment fataki n 3', 'vente des habits , style mixte ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243974037720', '+243974037720');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('KASTRO FASHIO', 'galerie mukondi,n°14', 'vente des habits et  souliers ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243974185286', '+243974185286');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('JOLIE EBENEZER', 'galerie mbanga,n A13', 'ventes des habits style homme', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243974232647', '+243974232647');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('JAMAICAIN FASHION ', 'butembo,rue d''ambiance ', 'vente des habits ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243974686332', '+243974686332');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MAMAN BRINO', 'kyanamire', '', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243974894713', '+243974894713');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MAISON RANGI ', 'rue présidentielle ', 'ventes des pagnes', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243974973022', '+243974973022');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LA MERVEILLE', 'av lulengo', 'vente de soulier', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243975223704', '+243975223704');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('KENNEDY', 'ngule', 'vente des marchandises ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243975545108', '+243975545108');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('AIME ELEKO CHOPING SOULIER ', 'galerie kyanamire numéro 53', 'choisir ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_20240608_104331.jpg?alt=media&token=969ffbd7-254e-4933-afaa-f86069be8d32', '+243975550468', '+243975550468');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MWANGAZA FASSIONS', 'fondation kitsa furaha', 'habillent', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243975564860', '+243975564860');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('COIN DES JEUNES ', 'galerie mukondi n18', 'ventes habits et souliers et accesoires pour hommes', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1705940287085.jpg?alt=media&token=40622902-8c2b-491a-aa86-1c91e0d01160', '+243975703948', '+243975703948');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('KBG SHOP', 'vusehi', 'vente accessores,  souliers, sous vêtements,  fabrication des fleurs et bracelets. ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_IMG-20240530-WA0036.jpg?alt=media&token=dc8808ae-bee6-4b5f-9691-8344793b4a1c', '+243975738343', '+243975738343');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('COULEUR D''ORIGINE ', 'galerie elisabeth  n°4', 'ventes des moteurs et congélateur ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243975827512', '+243975827512');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LA MERVEILLE', 'butembo, galerie jolie reve face à face à maison haojue', 'vente des pagrnes', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243975894830', '+243975894830');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('TEST', 'test', 'test', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243975955375', '+243975955375');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('GRACE DIVINE', 'galerie Henri pierrard', 'vente sous vetement', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1000024924.jpg?alt=media&token=a7be9764-f93b-4e68-82b1-93b362f70fd8', '+243976226020', '+243976226020');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('SAM', 'rue président ', 'ventes des assiettes ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1000076638.jpg?alt=media&token=8d74c7f9-27ba-471e-b408-edf4209ed386', '+243977062721', '+243977062721');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('WIVINE HAUSE', 'av makasi', 'fashion', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_Screenshot_2024-06-28-18-30-27-49.png?alt=media&token=90d2ebfa-e9b6-43a7-a6c8-6e0f9ce451bd', '+243977216120', '+243977216120');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('GLOIRE À DIEU', 'galerie mukundi,n°11', 'ventes des habits et souliers', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243977243354', '+243977243354');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('RICHARD', 'lubero', 'vente meuble de construction', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243977336259', '+243977336259');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('KAPIPI BUSINESS ', 'l''international ', 'vente de téléphone et accessoires ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1000060821.jpg?alt=media&token=76f63337-d6a6-4f0c-b950-f37edd297a1b', '+243977417836', '+243977417836');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LK SHOP', 'galerie muhyana', 'vente des plantes, perruque,mèche et autres accessoires', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243977485633', '+243977485633');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('ISABELLE CHOIX', 'av, lubero', 'habillement', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_Screenshot_2024-06-03-04-11-54-03.png?alt=media&token=475c937b-5d9c-4bfd-8c26-d8601a5f92a7', '+243977494964', '+243977494964');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('BILALY DESIGN', 'Beni ville', 'Design Graphique', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_PROFIL%20FB.jpg?alt=media&token=99fb3d3a-388a-42a8-87e6-aa66707ae310', '+243977646121', '+243977646121');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('API FASHION', 'kyanamire numéro 32', 'ventes des chaussures', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243977831830', '+243977831830');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('HK SHOP', 'galerie ndaliko2 n04', 'vente téléphone et accessoires', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243978078198', '+243978078198');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('SHALOM SERVICE ', 'butembo', 'vente de téléphone et accessoires.', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243978259574', '+243978259574');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('T-SQUARE SHOP', 'galerie palos', 'habillement ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243978438952', '+243978438952');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LA BÉNÉDICTION DE L''ÉTERNEL ', 'Bbo, galerie de la paix n10B', 'ventes des pagnes ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243978935345', '+243978935345');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('USHINDI VETERINARY ', '782810', 'vented d''aliment pour le poule, pore', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243979281082', '+243979281082');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('HM SHOP ', 'Butembo ', 'Boutique de vente des téléphones mobiles', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1000134837.jpg?alt=media&token=57996745-39aa-4338-946d-c8a1ce15bd34', '+243979325501', '+243979325501');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('DIDAS', 'av de l''eglise', 'électrique', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243979635055', '+243979635055');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ PAPA SAMUEL ', 'Bbo av ngulo', 'vente boissons ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243979824858', '+243979824858');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CADELL MANAGEMENT', 'Nord-Kivu/butembo', 'ventes habits et accessoires ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243984182851', '+243984182851');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MLINZI TECHNOLOGIES ', 'Goma', 'informatique ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243990084881', '+243990084881');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ SOLANGE', 'Bbo av du marché', 'vente  cacao en poudre ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243990307772', '+243990307772');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('TOUT EST GRACE', 'rue d''ambiance ', 'vente chaussure ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243990421772', '+243990421772');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('TOUT EST GRÂCE', 'galerie Mukondi ', 'ventes et locations style dame et hommes', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243990481913', '+243990481913');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MARCELLA FASHION ', 'avenue ngulo numéro 6', 'vente perique ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243990672320', '+243990672320');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MIRACLE', 'Galerie Elizabeth no 37', 'ventes guitare, Moteur, moulins ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243990806151', '+243990806151');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('QUINCAILLERIE MODERNE ISHARA', 'Bbo rue kin bat vyambwera n', 'ventes des metal tillions', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243990962936', '+243990962936');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('PASCALINE', 'av,du cente', 'vente de triplex et coutur', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243991131330', '+243991131330');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ MAMAN SAGESSE', 'butembo, galerie Henri pierare n°59', 'vente des habits', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243991197763', '+243991197763');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ KAVIRA NIKOLE', 'galerie Henry pierrard n° 49', 'vente des assiettes ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243991315661', '+243991315661');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('PAR GRÂCE', 'galerie Elizabeth n 46', 'vente des télévisions et accessoires', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243991321468', '+243991321468');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('DIEU À EXOCET', 'galerie lulengo n°20', 'vente soulier', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243991469916', '+243991469916');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('KAV-UNGA ', 'butembo croisement rue d''ambiance et avenu du centre ', 'KAV-UNGA est une entreprise agroalimentaire qui produit les cereales blé mais sorgho eleusine et les légumineuses (soja) et les aliments des volailles ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_Screenshot_20240815-070914_Gallery.jpg?alt=media&token=5cbc943c-1b91-44ea-9100-2cd9861dfb7c', '+243991549736', '+243991549736');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHRIS MÉCANIQUE', 'avenue du centré', 'vente de machine a coudre', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_Screenshot_2024-07-01-18-56-21-97.png?alt=media&token=beec0dd3-c800-4af6-b11c-76336992866a', '+243991703939', '+243991703939');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MONT FLEURI ', 'Bbo , rue Kinshasa ,sortie hôpital matanda n 51', 'cliniques de beauté ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243991709318', '+243991709318');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MELISSA ', 'galerie kighuhania', 'vente des perruque, Mèche, closure et oil', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1000084622.jpg?alt=media&token=5e055c34-2c92-4c49-b617-ac246e223064', '+243991837215', '+243991837215');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ LYDIA', ' Bbo rue kin,bâtiment kyamolova', 'ventes pièce de rechange', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243992064466', '+243992064466');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('BOUTIQUE PASSAGE OBLIGÉ ', 'avenu matokeyo gallérie kuputu N9', 'vente accessoires ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_DSC_0669.jpg?alt=media&token=1fcfc369-79bd-4b8d-aa92-905dd18a6303', '+243992079270', '+243992079270');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MWISA', 'butembo, galerie felly kiyalala n°5', 'vente de habillement', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243992161652', '+243992161652');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MATELAS BOUTIQUE', 'av,matokeyo', 'matelas', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243992636206', '+243992636206');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('DIEU MERCI KAZI', 'kalerie kikuvu chez lincesier', 'maison d''habillement ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+24399341755', '+24399341755');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LOVIS', 'kyannamirre', 'chousur', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243993479443', '+243993479443');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('TASIMWA', 'galerie lulengo', 'vente soulier', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243993516356', '+243993516356');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('ASIFIWE MADE', 'galerie fataki', 'vante de anciete', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_IMG_20240620_170454_147.jpg?alt=media&token=f3902193-7219-42b2-9831-cfa98a14769e', '+243993534466', '+243993534466');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('GENTILLE ', 'kianamire numéro 32', 'choisir', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243993686459', '+243993686459');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('NZABO', 'galerie muhyana', 'vente des radios ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243993942533', '+243993942533');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('TOUT  VIENT DE DIEU', 'rue kin,', 'Quincaillerie ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243993961108', '+243993961108');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHRISTOPHE FASHION', 'matanda', 'vente de s abus', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243994018015', '+243994018015');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('NELLY FASHION', 'kyanamire', 'choisir ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1000137815.jpg?alt=media&token=f6a61a28-6665-4b14-b5f8-da5299bedc7f', '+243994282296', '+243994282296');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('ELVIS SHOP', 'rue Kinshasa ', 'vente de motos', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243994509133', '+243994509133');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('FLORFASHION', 'av du centre', 'habillement', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243994566263', '+243994566263');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('HMB GESELLSCHAFT ', 'Butembo rue d''ambiance ', '', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243995026257', '+243995026257');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MAGNIFIQUE ', 'avenue ngulo ', 'vente savon sac,movite, quartz mafuta ya gari,', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1000028024.jpg?alt=media&token=fe0479d5-82ab-49d5-87d1-69a28c2522ef', '+243995102045', '+243995102045');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('BONGISA SAPE', 'galerie enri pierare ', ' vente de  habit', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243995175102', '+243995175102');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LUCIE', 'Henry pierrard', 'vente montre', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243995309392', '+243995309392');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('BIJEM', 'rue kin', 'habillement', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243995314918', '+243995314918');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('GRÂCE À DIEU ', 'galerie  muyhana', 'ventre  Écran, téléphone  balance digital et autres  accessoire ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_20240623_155258.jpg?alt=media&token=656c88ec-c02b-45ad-8c2e-24fbe2dec055', '+243995329724', '+243995329724');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MAISON MAMAN ELIZA', 'av de l''eglise', 'vente de produits brassicole ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243995434195', '+243995434195');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MUSUVULIA', 'rue kin', 'menuiserie', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243995472915', '+243995472915');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('DIEU MERCI', 'galerie lulengo ', 'vente soulier', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243995519377', '+243995519377');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('FELICITE FASHION', 'galerie mukondi,n°10', 'vente des habits er souliers', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243995832849', '+243995832849');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ MAMAN CECILE', 'galerie kitsya furaha2 ,n°123', 'vente habits style homme', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243996502846', '+243996502846');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('SISI_FASHION', 'Butembo', 'Vente d''habits ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243996875350', '+243996875350');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LINGERIE FREEDOM ', 'Butembo', 'vente lingerie moderne et accessoires ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243997499850', '+243997499850');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('BOUTIQUE SANS NOM', 'avenue Ruchuru ', 'vente des pièces électronique ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_DSC_0061.JPG.jpg?alt=media&token=57f133b8-fb4b-4cf6-be35-e57061aca352', '+243997534726', '+243997534726');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('JOSUÉ ', 'rue kin', 'menuiserie', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243997551904', '+243997551904');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('ATELIER BORA', 'rue Kinshasa ', 'garnissage menuiserie ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled__MG_0078_1POLO.jpg?alt=media&token=0f1e323c-31e7-4fcc-aed5-12b1d14bafe8', '+243997765409', '+243997765409');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MAISON KASALON', 'vungi', 'menuiserie', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243997805615', '+243997805615');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('THE ASSURANCE SHOP', 'Rue Presidentielle(grand route), cote a cote de la station Takenga, batiment kalamu services N•1', 'Ventes des styles Damme de lux.', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243998254168', '+243998254168');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('SANDRA FASHION ', 'galerie Elizabeth n41', 'vente des habits dames', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243998331615', '+243998331615');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('ELIE PETIT JEAN', 'rue kin', 'garnissage', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_Screenshot_20240624-052249.png?alt=media&token=acfdd76c-8ffa-43c6-add8-4ae40ccb905f', '+243998431298', '+243998431298');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('ALIMENTATION LA VIE EST UN COMBAT ', 'avenue d''eleglise ', 'vente oïl Rina, Muchel,majiwa ,jus, biscuits et excessoire ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1000070593.jpg?alt=media&token=2436a408-f3b0-42e9-8ff4-45bb096389ac', '+243998683522', '+243998683522');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('CHEZ MUNYAMBALO', 'galerie ndaliko n8', 'vente téléphone et radio', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243999048712', '+243999048712');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('FURAHA', 'rue à Kinshasa', 'produits cosmétiques', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_Snapchat-1855776583.jpg?alt=media&token=adcd7ec9-44bd-41ad-9fb0-26f53c86a4c3', '+243999817181', '+243999817181');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('LWANJO KARINE PANTAYO', 'kyanamite', 'chousir', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243999853906', '+243999853906');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('MAKUTSA', 'avenue de l''église ', 'produits manufacturés ', 'https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/avatar.png?alt=media&token=928f61fe-9c7d-4c94-a216-19c36723560b', '+243999891989', '+243999891989');

INSERT INTO shops (name, address, description, logo_url, phone, owner_id) VALUES ('B-MSON SERVICE ', 'Kamango, Watalinga, Beni, Nord-Kivu, RDC', 'Un service informatique pour aider les entreprises et clients à résoudre leurs besoins.', '158.jpg', '243975545108', '243975545108');


-- Products

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('PATALON ', '', 0, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719330076241.jpg?alt=media&token=616f2e0c-ecfa-44f6-a258-24f47c00418b"]', (SELECT id FROM shops WHERE phone = '+243974020193' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('GARNISSAGE ', '', 500, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719411154153.jpg?alt=media&token=ef473f30-d304-4f35-bdb1-66a03849bcbf"]', (SELECT id FROM shops WHERE phone = '+243997765409' LIMIT 1), (SELECT id FROM categories WHERE name = 'QUINCAILLERIE' LIMIT 1));

INSERT INTO categories (name) VALUES ('TÉLÉPHONES');

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('TÉLÉPHONE ', '', 0, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1734871818310.jpg?alt=media&token=1a2a5f44-7080-44c3-bb0d-d15c6ab6f901"]', (SELECT id FROM shops WHERE phone = '+243979325501' LIMIT 1), (SELECT id FROM categories WHERE name = 'TÉLÉPHONES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 10.8, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719225324923.jpg?alt=media&token=db7f479e-b539-4c0e-b60e-5d50dbfbab88"]', (SELECT id FROM shops WHERE phone = '+243990421772' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSETTE', '', 6.5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719320364548.jpg?alt=media&token=7bb43456-a6c4-4769-8608-de9a936116b0"]', (SELECT id FROM shops WHERE phone = '+243972417493' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', 'n 41', 25, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719315193542.jpg?alt=media&token=df3ce4a2-ecfb-4953-be0a-bb479f3f8e0a"]', (SELECT id FROM shops WHERE phone = '+243828041472' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', 'n 40', 25, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719310857702.jpg?alt=media&token=4a158f91-d2ea-4a8d-bbd4-8bbaacc504ab"]', (SELECT id FROM shops WHERE phone = '+243975703948' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 30.45, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719330859052.jpg?alt=media&token=9ab64e0b-770f-495a-88a1-c0b1547e32fa"]', (SELECT id FROM shops WHERE phone = '+243994018015' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('MOTO', 'haojin ', 1500, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1726341270572.jpg?alt=media&token=9a477612-3f08-44b1-8b70-125975202e7e"]', (SELECT id FROM shops WHERE phone = '+243970413058' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTOMOBILE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('IPHONES ANDROID, MA TOUCHE, TONDEUSE KWA BEI MBALU MBALI', '', 80.75, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719485970860.jpg?alt=media&token=5f8066d5-fad9-415a-9b9e-6c130759b31a"]', (SELECT id FROM shops WHERE phone = '+243995329724' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('PERRUQUE, PLANTE, MÈCHES, CLOSURE OIL ', 'gros et détails ', 55.75, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719487010621.jpg?alt=media&token=c2d3697e-8e0b-428a-a578-525183d79fd8"]', (SELECT id FROM shops WHERE phone = '+243991837215' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('TRICOT', 'm,xl,xxl', 7, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719313725742.jpg?alt=media&token=6ea042ff-f4ab-4f5b-8183-d5bfea9bc2d2"]', (SELECT id FROM shops WHERE phone = '+243996502846' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('PANTALON JEANS', 'XL, xxl', 10.12, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719317778306.jpg?alt=media&token=0e17e786-58bd-4dd2-96e8-6c77873ded81"]', (SELECT id FROM shops WHERE phone = '+243975564860' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ROBE', 'x,xl,xxl', 15, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719648364886.jpg?alt=media&token=ab1e1ef7-a99a-43fc-9768-fe493c00b0d2"]', (SELECT id FROM shops WHERE phone = '+243810766933' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 20, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719392022742.jpg?alt=media&token=3ab59c17-04e6-459c-ab68-07c65b6dfed1"]', (SELECT id FROM shops WHERE phone = '+243971479052' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('FEN DIN', 'moyenne', 7, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719304068757.jpg?alt=media&token=8184d12d-4686-4d94-926d-1e597500d058"]', (SELECT id FROM shops WHERE phone = '+243995832849' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('BIJOUX', 'gros et détail. ', 5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_bb7d7e43da214d37b124af6097c0fbda.jpg?alt=media&token=47c1a1b0-6597-4fb7-bf35-2309e9a103f7"]', (SELECT id FROM shops WHERE phone = '+243972124672' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('VESTE', '', 95, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719222541621.jpg?alt=media&token=76cb37a5-af70-489d-a4fd-e42e1c246f5d"]', (SELECT id FROM shops WHERE phone = '+243895570930' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', 'n 38,39,40,41', 30, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719352068126.jpg?alt=media&token=0aaa2698-90a8-4c3b-af1e-53e7d72a84b3"]', (SELECT id FROM shops WHERE phone = '+243842286271' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('TRANSMISSION ', '', 12, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719496570376.jpg?alt=media&token=69d1780b-c873-4389-9e8a-48a2b195dbfd"]', (SELECT id FROM shops WHERE phone = '+243857881641' LIMIT 1), (SELECT id FROM categories WHERE name = 'TECHNOLOGIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('OKINGF14', '', 8, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719494825688.jpg?alt=media&token=de26ada2-a965-4069-a48f-a25604c73379"]', (SELECT id FROM shops WHERE phone = '+243893813625' LIMIT 1), (SELECT id FROM categories WHERE name = 'TÉLÉPHONES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CAMON16', '', 0, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719400228857.jpg?alt=media&token=4c043fab-446c-41d7-a0fc-7d8641aa0169"]', (SELECT id FROM shops WHERE phone = '+243833695500' LIMIT 1), (SELECT id FROM categories WHERE name = 'TECHNOLOGIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('SACS DE VOIYAGE', 'durable', 25, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719414552061.jpg?alt=media&token=0eb8b8fc-949c-48b8-9e10-15105b56e0fc"]', (SELECT id FROM shops WHERE phone = '+243977216120' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('MENUISERIE', '', 135, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719504081300.jpg?alt=media&token=b25037ae-18e3-4e97-b630-2f70f90770db"]', (SELECT id FROM shops WHERE phone = '+243971142794' LIMIT 1), (SELECT id FROM categories WHERE name = 'QUINCAILLERIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CANAPE', '', 500.1000, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719411549709.jpg?alt=media&token=30c804c0-eb21-414c-b9ed-39a035fa8b1a"]', (SELECT id FROM shops WHERE phone = '+243998431298' LIMIT 1), (SELECT id FROM categories WHERE name = 'QUINCAILLERIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('DAMES', '', 15.20, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719585981497.jpg?alt=media&token=7c037969-d3be-4909-a3a1-4d93f7d65687"]', (SELECT id FROM shops WHERE phone = '+243972960821' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('BOISSON', '', 8, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719642773505.jpg?alt=media&token=2a4b9d9f-9866-4660-ae3b-53cc99c51e9b"]', (SELECT id FROM shops WHERE phone = '+243979824858' LIMIT 1), (SELECT id FROM categories WHERE name = 'FAST FOOD' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('RADIO ', '', 5.6, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1720620210742.jpg?alt=media&token=b595e7dd-a26e-4112-ab02-c4f6a1367fb5"]', (SELECT id FROM shops WHERE phone = '+243894549026' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSETTE', '', 6, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719320826038.jpg?alt=media&token=aac30497-d595-4c3a-b2b6-b948ea55e73c"]', (SELECT id FROM shops WHERE phone = '+243972417493' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('SABOT', 'toute couleur ', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719304193607.jpg?alt=media&token=50f05e2d-358b-4081-ac42-b628708e26a9"]', (SELECT id FROM shops WHERE phone = '+243995832849' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ROBE', 'l.xl.xxl,xxxl', 22, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719301295075.jpg?alt=media&token=1e588673-4f10-404b-98d4-0f05abdc5a54"]', (SELECT id FROM shops WHERE phone = '+243813557132' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('BIJOUX', '', 5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719854674881.jpg?alt=media&token=5040679d-64c2-426e-b7c2-e88de88cf7f6"]', (SELECT id FROM shops WHERE phone = '+243972124672' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('SEMOULE (FARINE DE MAÏS)', '', 5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1725045459945.jpg?alt=media&token=c3ba0185-3a20-45a1-9cc8-89bed091f22e"]', (SELECT id FROM shops WHERE phone = '+243991549736' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '36,42', 6.5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719323454038.jpg?alt=media&token=ebd61d76-cb3a-40f6-ad66-70bf4e1a7085"]', (SELECT id FROM shops WHERE phone = '+243993686459' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 10.15, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719225414960.jpg?alt=media&token=3d15fa1c-9281-4618-87bd-b53ec2b8c19c"]', (SELECT id FROM shops WHERE phone = '+243990421772' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ROBE', '', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1720501715145.jpg?alt=media&token=8adb8393-cdc2-4538-a84a-11ba2e4af6f7"]', (SELECT id FROM shops WHERE phone = '+243995175102' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('HUILE ', '5litre, 15litres,20litres', 7.5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719642119255.jpg?alt=media&token=f5c2bb76-d5a7-47af-95fc-18a2ddb5e2a9"]', (SELECT id FROM shops WHERE phone = '+243971223342' LIMIT 1), (SELECT id FROM categories WHERE name = 'FAST FOOD' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ROBES, COMBINAISONS, PANTALON TISSU', '', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719223844503.jpg?alt=media&token=c61023de-7f19-4ce3-995f-0ac0c69d320a"]', (SELECT id FROM shops WHERE phone = '+243848664025' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('PERRUQUE ', '24pouce', 85, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719487993342.jpg?alt=media&token=f5d77237-8c4c-45c1-be27-086013878438"]', (SELECT id FROM shops WHERE phone = '+243991837215' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('AUTRES', 'embolie,écran, bance digital ', 85.40, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719485031978.jpg?alt=media&token=e3feac49-f349-4a26-8b1f-97bcfdf33c40"]', (SELECT id FROM shops WHERE phone = '+243995329724' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 100, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719331292396.jpg?alt=media&token=adb53341-a6ae-45a0-a0fb-85942f467919"]', (SELECT id FROM shops WHERE phone = '+243994018015' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_IMG_20240625_113809_803.jpg?alt=media&token=9f00ed60-8251-4fbc-a441-78bf1e767a5f"]', (SELECT id FROM shops WHERE phone = '+243993516356' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('SANDALE', 'Original', 20, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1731392984221.jpg?alt=media&token=2cfaff9f-4a98-4f03-8d3f-962b2653615e"]', (SELECT id FROM shops WHERE phone = '+243998254168' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('VOILE', 'xx''m''l''ll', 20, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719309433544.jpg?alt=media&token=128b7f2e-3653-45cd-9867-a54c5f713065"]', (SELECT id FROM shops WHERE phone = '+243990481913' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHEMISE', '', 0, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719330351301.jpg?alt=media&token=0efab79b-cd36-45db-9096-3fe3f52afcd4"]', (SELECT id FROM shops WHERE phone = '+243974020193' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 15, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719337756884.jpg?alt=media&token=7c63c184-083c-4d4d-9252-d08bf043f5f4"]', (SELECT id FROM shops WHERE phone = '+243995519377' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('VESTE', '', 95, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719222176762.jpg?alt=media&token=bcdde879-4611-4341-80e5-5ca985335dfb"]', (SELECT id FROM shops WHERE phone = '+243895570930' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('SELFIE ', 'Robot caméra ', 7, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719514211000.jpg?alt=media&token=9c433ee6-528e-44e0-81ae-4f784799e55f"]', (SELECT id FROM shops WHERE phone = '+243992079270' LIMIT 1), (SELECT id FROM categories WHERE name = 'TÉLÉPHONES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('MONTRE ', '', 5.10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_1000203078.jpg?alt=media&token=466453ef-a6d6-4216-bbb8-75fa3625e61d"]', (SELECT id FROM shops WHERE phone = '+243894885314' LIMIT 1), (SELECT id FROM categories WHERE name = 'TECHNOLOGIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('PANCOA', '', 4, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719677785052.jpg?alt=media&token=b601147c-600d-44a9-aa7f-800b92379488"]', (SELECT id FROM shops WHERE phone = '+243972791964' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CALECON', 'malenda', 20, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719302932770.jpg?alt=media&token=ff42e788-73c0-45db-be6f-54b37a5224bf"]', (SELECT id FROM shops WHERE phone = '+243976226020' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '39', 35, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719636305837.jpg?alt=media&token=1dd9ac37-b8e2-422d-bbb0-c3c8412de2e2"]', (SELECT id FROM shops WHERE phone = '+243977243354' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('SAMSUNG', 'Samsung S20 128Gb', 120, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1732462712205.jpg?alt=media&token=42379698-ed4e-423c-b9a1-5d345c1adbc9"]', (SELECT id FROM shops WHERE phone = '+243979325501' LIMIT 1), (SELECT id FROM categories WHERE name = 'TÉLÉPHONES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('MENUISERIE', '', 1000, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719411516327.jpg?alt=media&token=a4debaf4-fc0e-4ab1-aa2c-6786878c18d0"]', (SELECT id FROM shops WHERE phone = '+243997765409' LIMIT 1), (SELECT id FROM categories WHERE name = 'QUINCAILLERIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('MONTRE', '', 0, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719490161867.jpg?alt=media&token=8773183d-1e8f-4074-ac5a-22b72b7cf51f"]', (SELECT id FROM shops WHERE phone = '+243816993446' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('MENUISERIE', '', 800, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719427032379.jpg?alt=media&token=cf042190-eb87-4d29-b52c-d63e40932dbd"]', (SELECT id FROM shops WHERE phone = '+243998431298' LIMIT 1), (SELECT id FROM categories WHERE name = 'QUINCAILLERIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('AUTRES', 'Affiche de publicité sur les réseaux sociaux', 5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1726727773370.jpg?alt=media&token=cb6b43a7-c013-4dbe-a291-b080a5a099ac"]', (SELECT id FROM shops WHERE phone = '+243819482397' LIMIT 1), (SELECT id FROM categories WHERE name = 'TECHNOLOGIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('WESTON', '', 35, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719396273969.jpg?alt=media&token=3091591a-a883-4242-9876-ed686f445fee"]', (SELECT id FROM shops WHERE phone = '+243995832849' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ROBE', 'xxl', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719596391166.jpg?alt=media&token=92b31e2d-15fb-4318-8859-197d1a3fda98"]', (SELECT id FROM shops WHERE phone = '+243977216120' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO shops (name, phone, owner_id) VALUES ('BOUTIQUE INCONNUE (+243808660965)', '+243808660965', '+243808660965');

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ELECTRONIQUE', '', 20.15, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719495662734.jpg?alt=media&token=83b70e86-646a-45a4-b17d-fb2c47f66a43"]', (SELECT id FROM shops WHERE phone = '+243808660965' LIMIT 1), (SELECT id FROM categories WHERE name = 'QUINCAILLERIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 15, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719392346308.jpg?alt=media&token=20b70f5f-cf6b-45f8-b6fb-822f70d12de0"]', (SELECT id FROM shops WHERE phone = '+243971479052' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ROBE', 'x,xxl, xxxl', 25, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719822015846.jpg?alt=media&token=b8dbfe05-06e5-4e83-8124-ac3e7506d4f0"]', (SELECT id FROM shops WHERE phone = '+243992161652' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', 'n°39', 40, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719305510027.jpg?alt=media&token=a89be833-8d89-4208-a77a-b8b22f0cf115"]', (SELECT id FROM shops WHERE phone = '+243974185286' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 45, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719331079846.jpg?alt=media&token=aff24d54-c95c-41ce-a082-227fc8e9c1c1"]', (SELECT id FROM shops WHERE phone = '+243994018015' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 7, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719320539117.jpg?alt=media&token=17c27d7a-b123-4626-bec9-f761304f6953"]', (SELECT id FROM shops WHERE phone = '+243972417493' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 8, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719225571270.jpg?alt=media&token=9ef573f4-d350-44e0-b38b-65badf684da0"]', (SELECT id FROM shops WHERE phone = '+243990421772' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CACAO EN POUDRE ', '½kg', 7.5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719638556636.jpg?alt=media&token=d2910add-3c3b-4945-89f2-34d116b5a669"]', (SELECT id FROM shops WHERE phone = '+243990307772' LIMIT 1), (SELECT id FROM categories WHERE name = 'FAST FOOD' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('AUTRES', '', 20, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1720083155061.jpg?alt=media&token=a27bb14e-1df5-4cae-b22d-ff72c24466ff"]', (SELECT id FROM shops WHERE phone = '+243991703939' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('MEUBLES', '', 215, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719592015865.jpg?alt=media&token=83dbad1b-9c00-4f17-b7a2-4df439953de1"]', (SELECT id FROM shops WHERE phone = '+243833916255' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CANAPÉ ', '', 0, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719504118579.jpg?alt=media&token=1b655773-8bcf-4d95-92e7-017ad4c28462"]', (SELECT id FROM shops WHERE phone = '+243970128303' LIMIT 1), (SELECT id FROM categories WHERE name = 'QUINCAILLERIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719225500163.jpg?alt=media&token=33ae60bf-4b1e-4e6e-8911-fbbaecac8a6e"]', (SELECT id FROM shops WHERE phone = '+243990421772' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719572270112.jpg?alt=media&token=93ea0caf-e104-4e1a-a72f-c9cab59e2cf2"]', (SELECT id FROM shops WHERE phone = '+243813733000' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ROBE', 'voilà la robe du Jour', 20, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1732303029999.jpg?alt=media&token=0ec4302f-b36b-458b-ae33-8b4be1a5477e"]', (SELECT id FROM shops WHERE phone = '+243996875350' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 3.5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719308439814.jpg?alt=media&token=10ecb94a-93a5-4b78-9d2b-903ed1c5eba5"]', (SELECT id FROM shops WHERE phone = '+243993516356' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('AUTRES', '', 55, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719487720395.jpg?alt=media&token=d9c5f541-4b57-457b-a8ed-309f49f53cb0"]', (SELECT id FROM shops WHERE phone = '+243991837215' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CALECON', '', 12, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719303063858.jpg?alt=media&token=fc65e66b-35cd-4513-b3b8-661a26240fa1"]', (SELECT id FROM shops WHERE phone = '+243976226020' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ÉCRAN ', '', 80, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719486606410.jpg?alt=media&token=ce6f0aca-939f-4f40-9321-f9f336246605"]', (SELECT id FROM shops WHERE phone = '+243995329724' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 15, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719309301872.jpg?alt=media&token=bd235f9c-b731-4bda-81ef-af0bb35d6c87"]', (SELECT id FROM shops WHERE phone = '+243993516356' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '36,42', 6.5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719323124353.jpg?alt=media&token=7857e35b-e55d-4b44-8d4c-b898bed07545"]', (SELECT id FROM shops WHERE phone = '+243993686459' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('TURBO, PRIMUS', '', 175, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719492781393.jpg?alt=media&token=152d6aac-3c12-49b9-b42c-ad0f5ce07f69"]', (SELECT id FROM shops WHERE phone = '+243995434195' LIMIT 1), (SELECT id FROM categories WHERE name = 'FAST FOOD' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('DAMES', 'x,xxl,', 20, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719309767875.jpg?alt=media&token=35dcee77-387f-4c3f-971a-6a612d6702a4"]', (SELECT id FROM shops WHERE phone = '+243990481913' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('MONTRE ', '', 5.10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719320947639.jpg?alt=media&token=69867853-b83a-4f11-ad86-99925d0d3a76"]', (SELECT id FROM shops WHERE phone = '+243894885314' LIMIT 1), (SELECT id FROM categories WHERE name = 'TECHNOLOGIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('SAMSUNG', 'Samsung S8 ', 75, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1732271855796.jpg?alt=media&token=b6f46ee6-de1c-4663-8a3d-20c8ce55085b"]', (SELECT id FROM shops WHERE phone = '+243979325501' LIMIT 1), (SELECT id FROM categories WHERE name = 'TÉLÉPHONES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('T-SHIRT', '', 7, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719329772874.jpg?alt=media&token=2f52c552-5030-4ffb-b103-a8be9146bd7f"]', (SELECT id FROM shops WHERE phone = '+243974020193' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719313704458.jpg?alt=media&token=255ed1e3-9324-470f-b46a-c2e9a609525b"]', (SELECT id FROM shops WHERE phone = '+243991469916' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('AUTRES', '', 140, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719592491494.jpg?alt=media&token=d1c8400a-413c-485a-a891-1fb949d9abb2"]', (SELECT id FROM shops WHERE phone = '+243833916255' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('MENUISERIE', '', 150.135, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719503850460.jpg?alt=media&token=d69bfc5e-a01c-41a2-a9f9-c45a93a557d7"]', (SELECT id FROM shops WHERE phone = '+243971142794' LIMIT 1), (SELECT id FROM categories WHERE name = 'QUINCAILLERIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('JUPE', 'xxxl ,très durable', 5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1725748914653.jpg?alt=media&token=6c12881d-46e3-43e8-ab50-1469ec70f19f"]', (SELECT id FROM shops WHERE phone = '+243977494964' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 5.3, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719322801325.jpg?alt=media&token=859bfc70-c9b2-4167-ad6a-3ab17806d07e"]', (SELECT id FROM shops WHERE phone = '+243977831830' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('BIJOUX', '', 5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719465662220.jpg?alt=media&token=9fd9ccc8-e55b-48f5-8c00-0759cfa521ad"]', (SELECT id FROM shops WHERE phone = '+243972124672' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('TRICOT', 'm,xl,xxl', 7, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719313725742.jpg?alt=media&token=922c7733-c784-4aad-9ffa-8a460c75d64e"]', (SELECT id FROM shops WHERE phone = '+243996502846' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('SOULIERS', 'homme', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1724495791080.jpg?alt=media&token=586cf42a-6afa-4938-b129-a4b6c8adc1bb"]', (SELECT id FROM shops WHERE phone = '+243975738343' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_IMG_20240619_102454_812.jpg?alt=media&token=f26b59a1-1097-4ee1-9a3b-db215961b224"]', (SELECT id FROM shops WHERE phone = '+243993516356' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('AUTRES', '', 55, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719401632849.jpg?alt=media&token=2dc3e725-fa06-43e5-8a9d-d6419eece55c"]', (SELECT id FROM shops WHERE phone = '+243995026257' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ROBE', '', 20.19, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719500217917.jpg?alt=media&token=21311933-b619-416e-8990-30f6c05e998e"]', (SELECT id FROM shops WHERE phone = '+24399341755' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 10.15, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719308331342.jpg?alt=media&token=07227528-b2b0-4ac2-a062-6d36b1ef4e5b"]', (SELECT id FROM shops WHERE phone = '+243993516356' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('OFF WITE', '', 25, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719396127289.jpg?alt=media&token=cd546544-1186-4c47-a499-f24777860702"]', (SELECT id FROM shops WHERE phone = '+243995832849' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('TALON DAME', '37,42', 15, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_IMG-20240624-WA0006.jpg?alt=media&token=1d885afd-724e-486c-b911-bb319b038ffd"]', (SELECT id FROM shops WHERE phone = '+243975550468' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CANAPÉ', '', 500.1000, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719411982327.jpg?alt=media&token=b695a76c-af5f-4153-b5af-1f6ec15b9115"]', (SELECT id FROM shops WHERE phone = '+243998431298' LIMIT 1), (SELECT id FROM categories WHERE name = 'QUINCAILLERIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ARMANI', '2xl', 12, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719321132611.jpg?alt=media&token=1c9f8afe-f769-43ea-833d-7f39ac6f552f"]', (SELECT id FROM shops WHERE phone = '+243974232647' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('MOTEUR POTERE', '', 85, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719481729530.jpg?alt=media&token=336fa316-e28d-4833-b225-05ff3472f122"]', (SELECT id FROM shops WHERE phone = '+243825294334' LIMIT 1), (SELECT id FROM categories WHERE name = 'TÉLÉPHONES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('MONTRE', '', 5.15, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719318813876.jpg?alt=media&token=3244056b-11d0-4b45-94c9-00de9c60d565"]', (SELECT id FROM shops WHERE phone = '+243894885314' LIMIT 1), (SELECT id FROM categories WHERE name = 'TECHNOLOGIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('TECNO', 'Tecno spark10 ', 90, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1732271342039.jpg?alt=media&token=298ef291-d6c3-4907-8ae8-775d9fb7c8de"]', (SELECT id FROM shops WHERE phone = '+243979325501' LIMIT 1), (SELECT id FROM categories WHERE name = 'TÉLÉPHONES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719314290067.jpg?alt=media&token=aa041617-70ac-4d26-9437-8e3fccf47fd5"]', (SELECT id FROM shops WHERE phone = '+243991469916' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 3.5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719308521463.jpg?alt=media&token=c104df7b-3d1c-42f1-88f1-e45ea7480d2c"]', (SELECT id FROM shops WHERE phone = '+243993516356' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CALECON', '12pieces', 5.5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719396030527.jpg?alt=media&token=07743033-decb-42a2-bde8-725596c47252"]', (SELECT id FROM shops WHERE phone = '+243827654725' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 15, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719309458292.jpg?alt=media&token=8bb3255c-c6a6-4384-bc97-13e66cb2a837"]', (SELECT id FROM shops WHERE phone = '+243993516356' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHEMISES', 's,l,xl,m', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719305376211.jpg?alt=media&token=0b7d9aab-38e4-415e-9793-5bac87020bc9"]', (SELECT id FROM shops WHERE phone = '+243974185286' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('TRICOT', 'm,xl,xxl', 7, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719313725742.jpg?alt=media&token=11f11e81-9939-4357-957e-5dc6b4d10922"]', (SELECT id FROM shops WHERE phone = '+243996502846' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('HUILE ', '', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719571290761.jpg?alt=media&token=9818a232-98d8-46e1-9a01-5fd0ebef0ca6"]', (SELECT id FROM shops WHERE phone = '+243991709318' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('DAMES', 'Tous les numeros sont disponinles ainsi que les couleurs', 30, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1731392658262.jpg?alt=media&token=edc30165-cd2c-406d-9f42-7f8f03a6d7d8"]', (SELECT id FROM shops WHERE phone = '+243998254168' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('FLEURS EN ARGENT(MONNAIE)', 'pour toutes vos  activités de fête(anniversaire, defense,..)', 5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1721381417985.jpg?alt=media&token=655e6d63-39af-4050-8a28-90d4d96d2601"]', (SELECT id FROM shops WHERE phone = '+243975738343' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('TECNO', '', 100, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1732281322321.jpg?alt=media&token=37df47b8-1042-4fdd-aa89-650a0878b1fe"]', (SELECT id FROM shops WHERE phone = '+243970501671' LIMIT 1), (SELECT id FROM categories WHERE name = 'TÉLÉPHONES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('S10', 'toutes les couleurs ', 2.5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719224506091.jpg?alt=media&token=bb726c2e-100f-40f2-9bdf-983338c04698"]', (SELECT id FROM shops WHERE phone = '+243972124672' LIMIT 1), (SELECT id FROM categories WHERE name = 'TÉLÉPHONES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('SAC VIDE', '', 0, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719587936199.jpg?alt=media&token=a58aa2dd-7cfb-4a2f-929b-fc4c32ab7b82"]', (SELECT id FROM shops WHERE phone = '+243816993446' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('PH', '', 12, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719839429696.jpg?alt=media&token=e7539d3a-2f75-4c09-bc21-42ab49aa032b"]', (SELECT id FROM shops WHERE phone = '+243975894830' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('VESTE', '46-68', 100, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719759155725.jpg?alt=media&token=37552779-2ec4-43b1-b03b-47320156955f"]', (SELECT id FROM shops WHERE phone = '+243823066980' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CEREAL+++', 'le céréal plus est un mélange des cereal maïs soja enrichie avec l''huile végétale et du sucre ', 2.5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1724561083006.jpg?alt=media&token=21ef88f8-9adc-4aff-9b17-9b80963c7933"]', (SELECT id FROM shops WHERE phone = '+243991549736' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('HOMME', 'matériaux durables et bonne apparence', 20.25, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/scaled_IMG-20240621-WA0042.jpg?alt=media&token=44dff90f-fe2e-4f00-86cc-d1446ef43f77"]', (SELECT id FROM shops WHERE phone = '+243971479052' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('HOUT PARLEUR ', '500w', 20, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719573090277.jpg?alt=media&token=dc64ead0-2e92-4c29-a409-15975c227d4e"]', (SELECT id FROM shops WHERE phone = '+243997534726' LIMIT 1), (SELECT id FROM categories WHERE name = 'QUINCAILLERIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('HAUT PARLEUR ', '250w', 15, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719573385881.jpg?alt=media&token=0f907c61-0bd3-4b9a-902b-082199bc1915"]', (SELECT id FROM shops WHERE phone = '+243997534726' LIMIT 1), (SELECT id FROM categories WHERE name = 'QUINCAILLERIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('PLUSIEURS MARQUES  DES TÉLÉPHONES ', 'itel,tecno ...', 11.7, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719495698885.jpg?alt=media&token=a8abc7e7-fcb5-48af-b4cf-0b820dfd27c5"]', (SELECT id FROM shops WHERE phone = '+243893813625' LIMIT 1), (SELECT id FROM categories WHERE name = 'TÉLÉPHONES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ROBES, COMBINAISONS, PANTALON TISSU', '', 10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719223753051.jpg?alt=media&token=8df773f7-df6c-41b0-b97d-b01a305762f4"]', (SELECT id FROM shops WHERE phone = '+243848664025' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('COMPLET FILLE', '', 6, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719841349568.jpg?alt=media&token=38978c26-0502-454e-aa18-663cfea02439"]', (SELECT id FROM shops WHERE phone = '+243813901957' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('MONTRE, CHENETTE, BIJOUX', '', 0, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719317797680.jpg?alt=media&token=c7077bb1-77f5-42ea-bce8-463ee0a1265c"]', (SELECT id FROM shops WHERE phone = '+243995309392' LIMIT 1), (SELECT id FROM categories WHERE name = 'TECHNOLOGIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 12, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719309121739.jpg?alt=media&token=2d46e494-8115-4c81-a81a-204ad2055620"]', (SELECT id FROM shops WHERE phone = '+243993516356' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('AUTRES', '', 80, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719487167942.jpg?alt=media&token=d12cc408-3972-4b6e-8877-91c2a0e5e352"]', (SELECT id FROM shops WHERE phone = '+243991837215' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 3.5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719319909971.jpg?alt=media&token=f9402b01-3be4-4b5e-b032-ed2df3a3e724"]', (SELECT id FROM shops WHERE phone = '+243972417493' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHENETTE,, MONTRE,, ', '', 1.2, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719317394890.jpg?alt=media&token=7e00c368-7276-4be7-ab6f-6dfeba07f248"]', (SELECT id FROM shops WHERE phone = '+243995309392' LIMIT 1), (SELECT id FROM categories WHERE name = 'TECHNOLOGIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('MENUISERIE', '', 400, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719411891222.jpg?alt=media&token=a6e33633-ac69-4b2e-b893-9f42dae3ce19"]', (SELECT id FROM shops WHERE phone = '+243997765409' LIMIT 1), (SELECT id FROM categories WHERE name = 'QUINCAILLERIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ROBE', '', 25, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719596688781.jpg?alt=media&token=675e3891-5408-4dc5-a2ec-23afde23c774"]', (SELECT id FROM shops WHERE phone = '+243977216120' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('OFF WITE', '', 25, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719396127289.jpg?alt=media&token=c15a4f46-781d-4408-9701-7e408284a0eb"]', (SELECT id FROM shops WHERE phone = '+243995832849' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ARMANI', '2xl', 12, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719321132611.jpg?alt=media&token=1c9f8afe-f769-43ea-833d-7f39ac6f552f"]', (SELECT id FROM shops WHERE phone = '+243974232647' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('IPHONES ANDROID, MA TOUCHE, TONDEUSE KWA BEI MBALU MBALI', '', 80.75, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719486025052.jpg?alt=media&token=328693c3-3954-4846-a18b-13784fceec0c"]', (SELECT id FROM shops WHERE phone = '+243995329724' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CALECON', 'coton', 18, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719302775792.jpg?alt=media&token=6a171cea-f0f8-4c80-98df-377a24b779a6"]', (SELECT id FROM shops WHERE phone = '+243976226020' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('SAMSUNG', 'Samsung S21 256Gb', 140, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1732462939687.jpg?alt=media&token=650c5eaf-e385-4a98-bbdf-6b0d1810d9d9"]', (SELECT id FROM shops WHERE phone = '+243979325501' LIMIT 1), (SELECT id FROM categories WHERE name = 'TÉLÉPHONES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('FER,AMPOULÉE, CHARGEUR', '', 0.8, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719485283809.jpg?alt=media&token=75ba8034-76aa-498d-8988-5b9b7c71f1d3"]', (SELECT id FROM shops WHERE phone = '+243995329724' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', 'numéro 40', 22, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719307241875.jpg?alt=media&token=f67d8dd7-11ac-40d5-8362-75b369ad600a"]', (SELECT id FROM shops WHERE phone = '+243977243354' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('DAMES', '', 5.10, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719406187595.jpg?alt=media&token=d624eade-f14b-466d-a0ce-0d99da00c7cb"]', (SELECT id FROM shops WHERE phone = '+243970974501' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('SOUTIENT', '', 2, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719224024600.jpg?alt=media&token=f27efa9f-83f1-4113-8f5c-88121dee9bd0"]', (SELECT id FROM shops WHERE phone = '+243848664025' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('DAMES', '', 2.5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719393289678.jpg?alt=media&token=42fcd452-36c6-4451-8705-dd07da5666ca"]', (SELECT id FROM shops WHERE phone = '+243973102757' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('LOUIS VUITTON ', 'xl', 4, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719060010894.jpg?alt=media&token=80f41c62-ece0-46d6-ab69-a681ec638438"]', (SELECT id FROM shops WHERE phone = '+243974686332' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('COMPLET FILLE', '26-48', 9, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719834332121.jpg?alt=media&token=8510f40c-32c9-40ff-96dd-abcfd07c99ba"]', (SELECT id FROM shops WHERE phone = '+243991197763' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHENETTE,, MONTRE,, ', '', 1.2, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719317394890.jpg?alt=media&token=bdb8ef5c-2ca9-4e9f-8c44-651e108fca6a"]', (SELECT id FROM shops WHERE phone = '+243995309392' LIMIT 1), (SELECT id FROM categories WHERE name = 'TECHNOLOGIE' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('PAGNE PH', '', 12, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719684480296.jpg?alt=media&token=3becaffa-d06d-4fe7-84e9-12b707dfb1ab"]', (SELECT id FROM shops WHERE phone = '+243978935345' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CHAUSSURE', '', 3.4, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719324554941.jpg?alt=media&token=afc01fce-c17f-40bf-b547-db35994b91c8"]', (SELECT id FROM shops WHERE phone = '+243994282296' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('ARMANI', '2xl', 12, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719321586397.jpg?alt=media&token=939caab3-235f-4699-8c8e-139f48f2046d"]', (SELECT id FROM shops WHERE phone = '+243974232647' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('PH', '', 11, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719845740492.jpg?alt=media&token=77d976c8-4ce6-4c0c-afd4-92a7197793f6"]', (SELECT id FROM shops WHERE phone = '+243974973022' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('VIVO', '64gigas', 30, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719412222123.jpg?alt=media&token=7ec70de8-1ddd-4c1a-8783-d3a3a7deab94"]', (SELECT id FROM shops WHERE phone = '+243812854735' LIMIT 1), (SELECT id FROM categories WHERE name = 'TÉLÉPHONES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('BLUETOOTH ', 'JBL prix de gros 5$', 5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719514506719.jpg?alt=media&token=c5e5f293-1b5c-4df5-bdec-c8fa9d6da367"]', (SELECT id FROM shops WHERE phone = '+243992079270' LIMIT 1), (SELECT id FROM categories WHERE name = 'TÉLÉPHONES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('DAMES', '', 10.5, '["https://firebasestorage.googleapis.com/v0/b/uzappv02.appspot.com/o/image_cropper_1719406263549.jpg?alt=media&token=8478334d-5744-473f-be8d-150e0b2a322a"]', (SELECT id FROM shops WHERE phone = '+243970974501' LIMIT 1), (SELECT id FROM categories WHERE name = 'HABILLEMENT' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CONCEPTION PHOTO DE MARIAGE', 'Conception logos', 20, '0bf830fa4dd2f1a7737b.png', (SELECT id FROM shops WHERE phone = '243975545108' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('CONCEPTION LOGOS', 'Nous concevons des meilleurs logos ', 20, 'db31488e0e7b2c05ef46.jpg', (SELECT id FROM shops WHERE phone = '243975545108' LIMIT 1), (SELECT id FROM categories WHERE name = 'AUTRES' LIMIT 1));

INSERT INTO products (name, description, price, image_urls, shop_id, category_id) VALUES ('UNIFY U16+', 'Unify U16+ Long Range', 200, 'f002af12f5530f3fb484.jpeg', (SELECT id FROM shops WHERE phone = '+243975955375' LIMIT 1), (SELECT id FROM categories WHERE name = 'TECHNOLOGIE' LIMIT 1));

